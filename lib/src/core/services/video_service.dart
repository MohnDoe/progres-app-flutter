import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart';
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart';

const kStabilizedVideoPrefix = 'timelapse_stabilized';
const kStabilizedVideoExt = 'mp4';

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

  Stream<VideoGenerationProgress> _prepareFrames(
    List<ProgressPicture> listPictures,
  ) async* {
    Logger().i('Preparing frames');
    final framesDirectory = await _framesDirectory;

    await _initFramesDirectory();

    Logger().i('Using ${listPictures.length} entries.');

    for (int i = 0; i < listPictures.length; i++) {
      final framePath = p.join(
        framesDirectory.path,
        'frame_${i.toString().padLeft(4, '0')}.jpg',
      );
      await listPictures[i].file.copy(framePath);
      yield VideoGenerationProgress(
        VideoGenerationStep.preparingFrames,
        (i + 1) / listPictures.length,
      );
    }
  }

  Stream<VideoGenerationProgress> _analyseVideo() async* {
    Logger().i('Analysing video.');
    final framesInputPattern = await _framesInputPattern;
    final transformsFilePath = await _transformsFilePath;
    await _deleteFile(transformsFilePath);

    final String analyzeCommand =
        "-i $framesInputPattern "
        "-vf vidstabdetect=shakiness=1:accuracy=15:result=\"$transformsFilePath\" "
        "-f null -";
    await for (final p in _executeCommand(analyzeCommand)) {
      yield VideoGenerationProgress(VideoGenerationStep.analyzing, p);
    }
  }

  Stream<VideoGenerationProgress> _stabilizeVideo(
    String stabilizedVideoPath,
  ) async* {
    Logger().i('Stabilizing video.');
    final framesInputPattern = await _framesInputPattern;
    final transformsFilePath = await _transformsFilePath;

    final String stabilizeCommand =
        "-i $framesInputPattern "
        "-vf vidstabtransform=input=\"$transformsFilePath\":smoothing=10,"
        "fps=10 "
        "-c:v libx264 -pix_fmt yuv420p "
        "$stabilizedVideoPath";

    await for (final p in _executeCommand(stabilizeCommand)) {
      yield VideoGenerationProgress(VideoGenerationStep.stabilizing, p);
    }
  }

  Future<void> _deleteFile(String path) async {
    if (await File(path).exists()) {
      await File(path).delete();
    }
  }

  Stream<VideoGenerationProgress> createVideo(
    ProgressEntryType entryType,
  ) async* {
    Logger().i('Creating video.');
    final List<ProgressPicture> listPictures = await PicturesFileService()
        .listPicturesForEntryType(entryType);

    yield VideoGenerationProgress(VideoGenerationStep.preparingFrames, 0);
    await for (final progress in _prepareFrames(listPictures)) {
      yield progress;
    }

    final temporaryDirectory = await _temporaryDirectory;
    final kStabilizedVideoFilename =
        '${kStabilizedVideoPrefix}_${entryType.name}.$kStabilizedVideoExt';
    final String stabilizedVideoPath = p.join(
      temporaryDirectory.path,
      kStabilizedVideoFilename,
    );
    await _deleteFile(stabilizedVideoPath);

    yield VideoGenerationProgress(VideoGenerationStep.analyzing, 0);
    await for (final progress in _analyseVideo()) {
      yield progress;
    }
    yield VideoGenerationProgress(VideoGenerationStep.analyzing, 1);

    yield VideoGenerationProgress(VideoGenerationStep.stabilizing, 0);
    await for (final progress in _stabilizeVideo(stabilizedVideoPath)) {
      yield progress;
    }

    print('Video generation complete. : $stabilizedVideoPath');
    yield VideoGenerationProgress(
      VideoGenerationStep.done,
      1,
      videoPath: stabilizedVideoPath,
    );
  }

  Stream<double> _executeCommand(String command) {
    final controller = StreamController<double>();
    final _duration = 0;

    FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          Logger().i('Command done.');
          controller.close();
        } else {
          final allLogs = await session.getAllLogsAsString();
          Logger().e('Command failed with logs: $allLogs');
          controller.addError('FFmpeg command failed');
          controller.close();
        }
      },
      // (log) => Logger().i(log.getMessage()),
      null,
      (statistics) {
        // First step is analysis, which does not provide progress updates.
        if (statistics.getVideoFrameNumber() > 0) {
          final progress =
              statistics.getVideoFrameNumber() / statistics.getVideoFps();
          controller.add(progress);
        }
      },
    );

    return controller.stream;
  }
}
