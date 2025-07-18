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

    final String analyzeCommand =
        "-i $framesInputPattern "
        "-vf vidstabdetect=shakiness=1:accuracy=15:result=\"$transformsFilePath\" "
        "-f null -";

    await _deleteFile(transformsFilePath);
    await for (final p in _executeCommand(analyzeCommand, frameCount)) {
      yield VideoGenerationProgress(VideoGenerationStep.analyzing, p);
    }
  }

  Future<void> _generateSubtitles(List<ProgressEntry> entries, int fps) async {
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

  List<SubtitleEntry> _getSubtitleEntries(
    List<ProgressEntry> entries,
    int fps,
  ) {
    List<SubtitleEntry> subtitles = [];
    int index = 0;
    double frameDurationInMilliseconds = 1000 / fps;
    for (ProgressEntry entry in entries) {
      String rawDateText = DateFormat.yMMMd().format(
        entry.date,
      ); // Or whatever text you use
      String cleanedDateText = rawDateText.replaceAll(
        '\x00',
        '',
      ); // Remove NULL characters

      if (rawDateText.length != cleanedDateText.length) {
        // Log if you found and removed NULL characters - good for debugging
        print(
          "WARNING: Removed NULL characters from subtitle text for entry date: ${entry.date}",
        );
      }
      final startTime = Duration(
        milliseconds: (frameDurationInMilliseconds * index).toInt(),
      );
      final SubtitleEntry subtitleEntry = SubtitleEntry(
        index: index,
        startTime: startTime,
        endTime:
            startTime +
            Duration(milliseconds: frameDurationInMilliseconds.toInt()),
        text: cleanedDateText,
      );

      subtitles.add(subtitleEntry);
      index++;
    }

    return subtitles;
  }

  Future<String> getSubtitleCommand() async {
    final subtitlesFilePath = await _subtitlesFilePath;

    final String primaryColorSubtitle = "&H0000FFFF"; // Opaque Yellow
    final String outlineColorSubtitle = "&H00000000";
    final String forceStyle =
        "Fontsize=36,"
        "FontName=Roboto-Regular" // Bigger font
        "PrimaryColour=$primaryColorSubtitle,"
        "BorderStyle=1," // Enable border/box
        "Outline=2,"
        "OutlineColour=$outlineColorSubtitle," // Black outline
        "BackColour=&H80000000"
        "";
    final String filterGraph =
        "subtitles=filename='$subtitlesFilePath'"
        ":force_style='$forceStyle'";

    return filterGraph;
  }

  Stream<VideoGenerationProgress> _stabilizeVideo(
    String stabilizedVideoPath,
    int frameCount,
  ) async* {
    Logger().i('Stabilizing video.');
    final framesInputPattern = await _framesInputPattern;
    final transformsFilePath = await _transformsFilePath;

    final String vidstabFilterGraph =
        "vidstabtransform=input='$transformsFilePath':smoothing=10";

    final subtitleFilterGraph = await getSubtitleCommand();

    final String stabilizeCommand =
        "-i $framesInputPattern "
        "-vf \"$vidstabFilterGraph,$subtitleFilterGraph\" "
        "-r 10 "
        "-c:v libx264 -pix_fmt yuv420p "
        "$stabilizedVideoPath";

    await _deleteFile(stabilizedVideoPath);
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
    final totalStepCount = VideoGenerationStep.values.length - 1; // -1 for done
    final oneStepCompletedProgress = 1 / totalStepCount;
    final temporaryDirectory = await _temporaryDirectory;
    final kStabilizedVideoFilename =
        '${kStabilizedVideoPrefix}_${entryType.name}.$kStabilizedVideoExt';

    final kOutputVideoFilename =
        'output_${entryType.name}.$kStabilizedVideoExt';
    final String outputVideoPath = p.join(
      temporaryDirectory.path,
      kOutputVideoFilename,
    );

    final String stabilizedVideoPath = p.join(
      temporaryDirectory.path,
      kStabilizedVideoFilename,
    );

    List<ProgressPicture> listPictures = await PicturesFileService()
        .listPicturesForEntryType(entryType);
    // TODO: delete this
    listPictures = listPictures.take(5).toList();

    List<ProgressEntry> entries =
        await PicturesFileService.listEntriesWithPictureOfType(entryType);

    // TODO: delete this
    entries = entries.take(5).toList();

    // GENERATE SUBTITLES FILE
    await _generateSubtitles(entries, fps);

    // PREPARING FRAMES : PUTTING THEM IN TEMP FOLDER IN ORDER

    yield VideoGenerationProgress(VideoGenerationStep.preparingFrames, 0);
    await for (final progress in _prepareFrames(listPictures)) {
      yield VideoGenerationProgress(
        progress.step,
        progress.progress / totalStepCount,
      );
    }

    // PREPARING FRAMES DONE

    // ANALYZING

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

    // ANALYZING DONE

    // STABILIZING

    yield VideoGenerationProgress(
      VideoGenerationStep.stabilizing,
      globalProgress.progress,
    );
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

    // STABILIZING DONE

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
