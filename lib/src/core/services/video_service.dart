import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart';
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart';
import 'package:subtitle_toolkit/subtitle_toolkit.dart';

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
  Future<String> get _subtitlesFilePath async =>
      p.join((await _temporaryDirectory).path, 'subtitles.srt');

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

  Stream<VideoGenerationProgress> _analyseVideo(int frameCount) async* {
    Logger().i('Analysing video.');
    final framesInputPattern = await _framesInputPattern;
    final transformsFilePath = await _transformsFilePath;
    await _deleteFile(transformsFilePath);

    final String analyzeCommand =
        "-i $framesInputPattern "
        "-vf vidstabdetect=shakiness=1:accuracy=15:result=\"$transformsFilePath\" "
        "-f null -";
    await for (final p in _executeCommand(analyzeCommand, frameCount)) {
      yield VideoGenerationProgress(VideoGenerationStep.analyzing, p);
    }
  }

  Future<void> _generateSubtitles(List<ProgressEntry> entries, int fps) async {
    print('Generating subtitles');
    final subtitlesFilePath = await _subtitlesFilePath;
    await _deleteFile(subtitlesFilePath);

    final subtitles = _getSubtitleEntries(entries, fps);

    await SubtitleParser.writeToFile(subtitles, subtitlesFilePath);

    print('Subtitles generated');
  }

  List<SubtitleEntry> _getSubtitleEntries(
    List<ProgressEntry> entries,
    int fps,
  ) {
    List<SubtitleEntry> subtitles = [];
    int index = 0;
    double frameDurationInMilliseconds = 1000 / fps;
    for (ProgressEntry entry in entries) {
      final startTime = Duration(
        milliseconds: (frameDurationInMilliseconds * index).toInt(),
      );
      final SubtitleEntry subtitleEntry = SubtitleEntry(
        index: index,
        startTime: startTime,
        endTime:
            startTime +
            Duration(milliseconds: frameDurationInMilliseconds.toInt()),
        text: DateFormat.yMMMd().format(entry.date),
      );

      subtitles.add(subtitleEntry);
      index++;
    }

    return subtitles;
  }

  Stream<VideoGenerationProgress> _stabilizeVideo(
    String stabilizedVideoPath,
    int frameCount,
  ) async* {
    Logger().i('Stabilizing video.');
    final framesInputPattern = await _framesInputPattern;
    final transformsFilePath = await _transformsFilePath;
    final subtitlesFilePath = await _subtitlesFilePath;

    final String primaryColorSubtitle = "\&H0000FFFF"; // Opaque Yellow
    final String outlineColorSubtitle = "\&H00000000";
    final String forceStyle =
        "Fontsize=36," // Bigger font
        "FontName='Arial',"
        "PrimaryColour=$primaryColorSubtitle,"
        "BorderStyle=1," // Enable border/box
        "Outline=2,"
        "OutlineColour=$outlineColorSubtitle," // Black outline
        "BackColour=\&H80000000";

    final String filterGraph =
        "vidstabtransform=input='$transformsFilePath':smoothing=10,"
        "subtitles=filename='$subtitlesFilePath'"
        ":force_style='$forceStyle'"
        ",";

    final String stabilizeCommand =
        "-i $framesInputPattern "
        "-vf \"$filterGraph\" "
        "-r 10 "
        "-c:v libx264 -pix_fmt yuv420p "
        "$stabilizedVideoPath";

    await for (final p in _executeCommand(stabilizeCommand, frameCount)) {
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
    final fps = 10;
    final List<ProgressPicture> listPictures = await PicturesFileService()
        .listPicturesForEntryType(entryType);

    await _generateSubtitles(
      await PicturesFileService.listEntriesWithPictureOfType(entryType),
      fps,
    );

    final totalStepCount = VideoGenerationStep.values.length - 1; // -1 for done
    final oneStepCompletedProgress = 1 / totalStepCount;
    yield VideoGenerationProgress(VideoGenerationStep.preparingFrames, 0);
    await for (final progress in _prepareFrames(listPictures)) {
      yield VideoGenerationProgress(
        progress.step,
        progress.progress / totalStepCount,
      );
    }

    final temporaryDirectory = await _temporaryDirectory;
    final kStabilizedVideoFilename =
        '${kStabilizedVideoPrefix}_${entryType.name}.$kStabilizedVideoExt';
    final String stabilizedVideoPath = p.join(
      temporaryDirectory.path,
      kStabilizedVideoFilename,
    );
    VideoGenerationProgress globalProgress = VideoGenerationProgress(
      VideoGenerationStep.analyzing,
      oneStepCompletedProgress,
    );
    yield globalProgress;
    await for (final analyseProgress in _analyseVideo(listPictures.length)) {
      globalProgress = VideoGenerationProgress(
        analyseProgress.step,
        oneStepCompletedProgress + analyseProgress.progress / totalStepCount,
      );
      yield globalProgress;
    }

    yield VideoGenerationProgress(
      VideoGenerationStep.stabilizing,
      globalProgress.progress,
    );

    await _deleteFile(stabilizedVideoPath);
    await for (final stabilizationProgress in _stabilizeVideo(
      stabilizedVideoPath,
      listPictures.length,
    )) {
      globalProgress = VideoGenerationProgress(
        stabilizationProgress.step,
        oneStepCompletedProgress * 2 + // *2 because it's the second step
            stabilizationProgress.progress / totalStepCount,
      );
      yield globalProgress;
    }

    print('Video generation complete. : $stabilizedVideoPath');
    yield VideoGenerationProgress(
      VideoGenerationStep.done,
      1,
      videoPath: stabilizedVideoPath,
    );
  }

  Stream<double> _executeCommand(String command, int frameCount) {
    final controller = StreamController<double>();

    FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          Logger().i('Command done. : $command');
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
          final progress = statistics.getVideoFrameNumber() / frameCount;
          controller.add(progress);
        }
      },
    );

    return controller.stream;
  }
}
