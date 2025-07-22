import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';

import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/ml_kit_service.dart';
import 'package:progres/src/features/timelapse/_shared/repositories/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart';
import 'package:subtitle_toolkit/subtitle_toolkit.dart';

class VideoService {
  static final kOutputVideoPrefix = 'generated_timelapse';
  static final kOutputVideoExt = 'mp4';

  Future<Directory> get _temporaryDirectory async => await getTemporaryDirectory();
  Future<Directory> get _framesDirectory async =>
      Directory(p.join((await _temporaryDirectory).path, 'frames'));

  Future<Directory> get alignedFramesDirectory async =>
      Directory(p.join((await _temporaryDirectory).path, 'aligned_frames'));

  Future<String> get _transformsFilePath async =>
      p.join((await _temporaryDirectory).path, 'transforms.trf');
  Future<String> get _subtitlesFilePath async =>
      p.join((await _temporaryDirectory).path, 'subtitles.srt');

  Future<String> get _framesInputPattern async =>
      p.join((await _framesDirectory).path, 'frame_%04d.jpg');

  Future<String> get _alignedFramesInputPattern async =>
      p.join((await alignedFramesDirectory).path, 'frame_%04d.jpg');

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

  Stream<VideoGenerationProgress> _generateBasicVideo(
    String outputVideoPath,
    int fps,
    int frameCount,
  ) async* {
    Logger().i('Generating basic video.');
    final framesInputPattern = await _framesInputPattern;

    final String compilingCommand =
        "-framerate $fps "
        "-i $framesInputPattern "
        "-r $fps "
        "-c:v libx264 -pix_fmt yuv420p "
        "$outputVideoPath";

    await _deleteFile(outputVideoPath);
    await for (final p in _executeCommand(compilingCommand, frameCount)) {
      yield VideoGenerationProgress(VideoGenerationStep.generating, p);
    }
  }

  Stream<VideoGenerationProgress> _generateVideoUsingAlignedFrames(
    String outputVideoPath,
    int fps,
    int frameCount,
  ) async* {
    Logger().i('Generating aligned video.');
    final framesInputPattern = await _alignedFramesInputPattern;

    final String compilingCommand =
        "-framerate $fps "
        "-i $framesInputPattern "
        "-vf \"pad=ceil(iw/2)*2:ceil(ih/2)*2\" " // fix not divisible by 2
        "-r $fps "
        "-c:v libx264 -pix_fmt yuv420p "
        "$outputVideoPath";

    await _deleteFile(outputVideoPath);
    await for (final p in _executeCommand(compilingCommand, frameCount)) {
      yield VideoGenerationProgress(VideoGenerationStep.generating, p);
    }
  }

  Stream<VideoGenerationProgress> _analyseFrames(int fps, int frameCount) async* {
    Logger().i('Analysing video.');
    final framesInputPattern = await _framesInputPattern;
    final transformsFilePath = await _transformsFilePath;

    final String analyzeCommand =
        "-framerate $fps "
        "-i $framesInputPattern "
        "-vf vidstabdetect=shakiness=1"
        ":accuracy=15"
        ":result=\"$transformsFilePath\" "
        "-f null -";

    await _deleteFile(transformsFilePath);
    await for (final p in _executeCommand(analyzeCommand, frameCount)) {
      yield VideoGenerationProgress(VideoGenerationStep.analyzing, p);
    }
  }

  Future<void> _generateSubtitlesFile(List<ProgressEntry> entries, int fps) async {
    print('Generating subtitles');
    final subtitlesFilePath = await _subtitlesFilePath;
    await _deleteFile(subtitlesFilePath);

    final subtitles = _getSubtitleEntries(entries, fps);

    // await SubtitleParser.writeToFile(subtitles, subtitlesFilePath);
    await File(subtitlesFilePath).writeAsString(
      SubtitleParser.entriesToString(subtitles).replaceAll('\x00', ''),
      encoding: Encoding.getByName('utf-8')!,
    );

    print('Subtitles generated');
  }

  List<SubtitleEntry> _getSubtitleEntries(List<ProgressEntry> entries, int fps) {
    List<SubtitleEntry> subtitles = [];
    Duration frameDuration = Duration(milliseconds: (1000 / fps).toInt());

    int index = 0;
    for (ProgressEntry entry in entries) {
      String cleanedDateText = DateFormat.yMMMd()
          .format(entry.date)
          .replaceAll('\x00', ''); // Remove NULL characters

      final startTime = Duration(milliseconds: (frameDuration.inMilliseconds * index));
      final endTime = startTime + frameDuration;

      final SubtitleEntry subtitleEntry = SubtitleEntry(
        index: index,
        startTime: startTime,
        endTime: endTime,
        text: cleanedDateText,
      );

      subtitles.add(subtitleEntry);
      index++;
    }

    return subtitles;
  }

  Future<String> getSubtitleCommand() async {
    final subtitlesFilePath = await _subtitlesFilePath;

    final String forceStyle =
        "Fontsize=14,"
        "FontName=Roboto-Regular"; // Bigger font
    final String filterGraph =
        "subtitles=filename='$subtitlesFilePath'"
        ":force_style='$forceStyle'";

    return filterGraph;
  }

  // Stream<VideoGenerationProgress> _stabilizeVideo(
  //   String stabilizedVideoPath,
  //   int fps,
  //   int frameCount,
  // ) async* {
  //   Logger().i('Stabilizing video.');
  //   final framesInputPattern = await _framesInputPattern;
  //   final transformsFilePath = await _transformsFilePath;
  //
  //   final String vidstabFilterGraph =
  //       "vidstabtransform=input='$transformsFilePath':smoothing=10";
  //
  //   final subtitleFilterGraph = await getSubtitleCommand();
  //
  //   final String stabilizeCommand =
  //       "-framerate $fps "
  //       "-i $framesInputPattern "
  //       "-vf \"$vidstabFilterGraph,$subtitleFilterGraph\" "
  //       "-r $fps "
  //       "-c:v libx264 -pix_fmt yuv420p "
  //       "$stabilizedVideoPath";
  //
  //   await _deleteFile(stabilizedVideoPath);
  //   await for (final p in _executeCommand(stabilizeCommand, frameCount)) {
  //     yield VideoGenerationProgress(VideoGenerationStep.stabilizing, p);
  //   }
  // }

  Future<void> _deleteFile(String path) async {
    if (await File(path).exists()) {
      await File(path).delete();
    }
  }

  Future<String> getVideoPath(String videoFilename) async {
    final temporaryDirectory = await _temporaryDirectory;

    return p.join(temporaryDirectory.path, videoFilename);
  }

  Stream<VideoGenerationProgress> createVideo(
    Timelapse configuration,
    String outputFilename,
  ) async* {
    Logger().i('Creating video. ');
    Logger().i(configuration);
    final totalStepCount = [
      VideoGenerationStep.preparingFrames,
      VideoGenerationStep.generating,
    ].length;
    final oneStepCompletedProgress = 1 / totalStepCount;

    final String outputVideoPath = await getVideoPath(outputFilename);

    List<ProgressPicture> listPictures = configuration.entries
        .where((entry) => entry.pictures[configuration.type] != null)
        .map((entry) => entry.pictures[configuration.type]!)
        .toList();

    // GENERATE SUBTITLES FILE
    // await _generateSubtitles(entries, fps);

    // PREPARING FRAMES : PUTTING THEM IN TEMP FOLDER IN ORDER

    // await for (final progress in _prepareFrames(listPictures)) {
    //   yield VideoGenerationProgress(
    //     progress.step,
    //     progress.progress / totalStepCount,
    //   );
    // }

    await for (final progress in MLKitService.generateAlignedImages(listPictures)) {
      yield VideoGenerationProgress(progress.step, progress.progress / totalStepCount);
    }

    // PREPARING FRAMES DONE
    yield VideoGenerationProgress(
      VideoGenerationStep.generating,
      oneStepCompletedProgress,
    );
    await for (final basicGenerationProgress in _generateVideoUsingAlignedFrames(
      outputVideoPath,
      configuration.fps,
      listPictures.length,
    )) {
      yield VideoGenerationProgress(
        basicGenerationProgress.step,
        oneStepCompletedProgress + basicGenerationProgress.progress / totalStepCount,
      );
    }

    print('Video generation complete. : $outputVideoPath');
    yield VideoGenerationProgress(
      VideoGenerationStep.done,
      1,
      videoPath: outputVideoPath,
    );
  }

  Stream<double> _executeCommand(String command, int frameCount) {
    Logger().i('Executing command: $command');
    final controller = StreamController<double>();

    FFmpegKitConfig.setFontDirectoryList(["/system/fonts", "/assets/fonts"]);

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
