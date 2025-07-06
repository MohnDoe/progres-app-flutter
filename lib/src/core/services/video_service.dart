import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/services/file_service.dart';

const kStabilizedVideoFilename = 'timelapse_stabilized.mp4';

class VideoService {
  Future<Directory> get _temporaryDirectory async =>
      await getTemporaryDirectory();
  Future<Directory> get _framesDirectory async =>
      Directory(p.join((await _temporaryDirectory).path, 'frames'));

  Future<String> get _framesInputPattern async =>
      p.join((await _framesDirectory).path, 'frame_%04d.jpg');
  Future<String> get _transformsFilePath async =>
      p.join((await _temporaryDirectory).path, 'transforms.trf');

  Future<void> _initFramesDirectory() async {
    final framesDirectory = await _framesDirectory;
    if (!await framesDirectory.exists()) {
      await framesDirectory.create();
    }
  }

  Future<void> _prepareFrames() async {
    print('Preparing frames');
    final List<File> listPictures = await PicturesFileService().listPictures();
    final framesDirectory = await _framesDirectory;

    await _initFramesDirectory();

    print('Using ${listPictures.length} pictures.');

    for (int i = 0; i < listPictures.length; i++) {
      final framePath = p.join(
        framesDirectory.path,
        'frame_${i.toString().padLeft(4, '0')}.jpg',
      );
      await listPictures[i].copy(framePath);
    }
  }

  Future<void> _analyseVideo() async {
    print('Analysing video.');
    final framesInputPattern = await _framesInputPattern;
    final transformsFilePath = await _transformsFilePath;
    // Step 1: Analyze motion vectors and create transform file
    await _deleteFile(transformsFilePath);

    final String analyzeCommand =
        "-i $framesInputPattern "
        "-vf vidstabdetect=shakiness=5:accuracy=15:result=\"$transformsFilePath\":tripod=1 "
        "-f null -";
    await _executeCommand(analyzeCommand);
  }

  Future<void> _stabilizeVideo(String stabilizedVideoPath) async {
    print('Stabilizing video.');
    final framesInputPattern = await _framesInputPattern;
    final transformsFilePath = await _transformsFilePath;

    final String stabilizeCommand =
        "-i $framesInputPattern "
        "-vf vidstabtransform=input=\"$transformsFilePath\":smoothing=10,"
        "scale=512:512:force_original_aspect_ratio=decrease,"
        "pad=ceil(iw/2)*2:ceil(ih/2)*2,"
        "fps=60 "
        "-c:v libx264 -pix_fmt yuv420p "
        "$stabilizedVideoPath";

    await _executeCommand(stabilizeCommand);
  }

  Future<void> _deleteFile(String path) async {
    if (await File(path).exists()) {
      await File(path).delete();
    }
  }

  Future<String> createVideo() async {
    print('Creating video.');

    await _prepareFrames();
    final temporaryDirectory = await _temporaryDirectory;

    final String stabilizedVideoPath = p.join(
      temporaryDirectory.path,
      kStabilizedVideoFilename,
    );

    // delete stabilized video if it exists
    await _deleteFile(stabilizedVideoPath);

    await _analyseVideo();

    // Step 2: Apply transforms to stabilize the video
    await _stabilizeVideo(stabilizedVideoPath);

    return stabilizedVideoPath;
  }

  Future<void> _executeCommand(String command) async {
    print(command);
    await FFmpegKit.execute(command);

    FFmpegSession session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      print('Command done.');
    }
  }
}
