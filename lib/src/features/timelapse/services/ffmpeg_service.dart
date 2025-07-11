import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/media_information.dart';
import 'package:ffmpeg_kit_flutter_new/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/utils/file_utils.dart';

// Define a class to hold FFmpeg results for better type safety
class FfmpegResult {
  final int returnCode;
  final String? outputPath; // Path to the generated video or transforms file
  final String? logs;

  FfmpegResult({required this.returnCode, this.outputPath, this.logs});

  bool get isSuccess => returnCode == 0;
}

class FfmpegService {
  final FFmpegKitConfig _flutterFFmpegConfig = FFmpegKitConfig();

  // --- Helper to prepare images (copy and rename) ---
  Future<String?> _prepareImagesForFfmpeg(
    List<File> sourceImageFiles,
    String tempSubDirName,
  ) async {
    if (sourceImageFiles.isEmpty) return null;

    final tempImageDir = await FileUtils.getTemporaryImageDir(tempSubDirName);

    for (int i = 0; i < sourceImageFiles.length; i++) {
      final newFileName =
          "img${(i + 1).toString().padLeft(4, '0')}.jpg"; // e.g., img0001.jpg
      try {
        await sourceImageFiles[i].copy(p.join(tempImageDir.path, newFileName));
      } catch (e) {
        print("Error copying image ${sourceImageFiles[i].path}: $e");
        await FileUtils.deleteDirectory(tempImageDir); // Clean up on error
        return null; // Indicate failure
      }
    }
    return p.join(tempImageDir.path, "img%04d.jpg"); // Return pattern
  }

  // --- Simple Timelapse (No Stabilization) ---
  Future<FfmpegResult> generateSimpleTimelapse({
    required List<File> imageFiles,
    required String outputVideoName, // e.g., "timelapse_front.mp4"
    required int fps,
  }) async {
    final imageInputPattern = await _prepareImagesForFfmpeg(
      imageFiles,
      "simple_timelapse_imgs",
    );
    if (imageInputPattern == null) {
      return FfmpegResult(returnCode: -1, logs: "Failed to prepare images.");
    }

    final outputPath = await FileUtils.getAppDocumentsPath(outputVideoName);
    await FileUtils.deleteFile(outputPath); // Delete if exists

    final command =
        "-framerate $fps -start_number 1 -i $imageInputPattern "
        "-c:v libx264 -pix_fmt yuv420p -movflags +faststart $outputPath";

    print("Executing Simple Timelapse: $command");
    final session = await FFmpegKit.execute(command);
    final logs = await session.getLogs();
    final rc = await session.getReturnCode();
    await FileUtils.deleteDirectory(
      Directory(p.dirname(imageInputPattern)),
    ); // Clean up temp images

    return FfmpegResult(
      returnCode: rc!.getValue() ?? ReturnCode.cancel,
      outputPath: rc.isValueSuccess() ? outputPath : null,
      logs: logs.toString(),
    );
  }

  // --- VidStab Detection Pass ---
  Future<FfmpegResult> runVidstabDetectPass({
    required List<File> imageFiles,
    required String transformsFileName, // e.g., "transforms_front.trf"
    required int fps,
    int shakiness = 5,
    int accuracy = 9,
  }) async {
    final imageInputPattern = await _prepareImagesForFfmpeg(
      imageFiles,
      "vidstab_detect_imgs",
    );
    if (imageInputPattern == null) {
      return FfmpegResult(
        returnCode: -1,
        logs: "Failed to prepare images for vidstab detect.",
      );
    }

    final transformsFilePath = await FileUtils.getAppDocumentsPath(
      transformsFileName,
    );
    await FileUtils.deleteFile(transformsFilePath);

    final command =
        "-framerate $fps -start_number 1 -i $imageInputPattern "
        "-vf vidstabdetect=shakiness=$shakiness:accuracy=$accuracy:result='$transformsFilePath' "
        "-f null -";

    print("Executing VidStabDetect: $command");
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    final logs = await session.getLogs();

    // Don't delete images yet, transform pass needs them
    // await FileUtils.deleteDirectory(Directory(p.dirname(imageInputPattern)));

    return FfmpegResult(
      returnCode: rc!.getValue() ?? ReturnCode.cancel,
      outputPath: rc.isValueSuccess() ? transformsFilePath : null,
      logs: logs.toString(),
    );
  }

  // --- VidStab Transform Pass ---
  Future<FfmpegResult> runVidstabTransformPass({
    required List<File>
    imageFiles, // FFmpeg needs access to the original image sequence again
    required String transformsFilePath, // From detect pass
    required String outputVideoName,
    required int fps,
    double zoom = 0, // 0 for optzoom=1 default behavior
    int smoothing = 10,
    String? tempImageSubDirForTransform, // The subdir used in detect pass
  }) async {
    // Re-prepare or reuse image pattern from detect pass
    // For simplicity, we assume images are still in the temp dir from detect pass, or re-prepare.
    // A more robust way would be to pass the temp dir path around.
    final imageInputPattern = tempImageSubDirForTransform != null
        ? p.join(
            (await FileUtils.getTemporaryImageDir(
              tempImageSubDirForTransform,
            )).path,
            "img%04d.jpg",
          )
        : await _prepareImagesForFfmpeg(imageFiles, "vidstab_transform_imgs");

    if (imageInputPattern == null) {
      return FfmpegResult(
        returnCode: -1,
        logs: "Failed to prepare images for vidstab transform.",
      );
    }

    final outputPath = await FileUtils.getAppDocumentsPath(outputVideoName);
    await FileUtils.deleteFile(outputPath);

    // optzoom=1 is default if zoom=0 is not explicitly set or zoom=0
    // If you want to explicitly control zoom, set it (e.g., zoom=1 for 1% zoom).
    // The unsharp filter is optional.
    final command =
        "-framerate $fps -start_number 1 -i $imageInputPattern "
        "-vf vidstabtransform=input='$transformsFilePath':zoom=$zoom:smoothing=$smoothing,unsharp=5:5:0.8:3:3:0.4 "
        "-c:v libx264 -pix_fmt yuv420p -movflags +faststart $outputPath";

    print("Executing VidStabTransform: $command");
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    final logs = await session.getLogs();

    // Clean up
    await FileUtils.deleteDirectory(Directory(p.dirname(imageInputPattern)));
    await FileUtils.deleteFile(transformsFilePath);

    return FfmpegResult(
      returnCode: rc!.getValue() ?? ReturnCode.cancel,
      outputPath: rc.isValueSuccess() ? outputPath : null,
      logs: logs.toString(),
    );
  }

  Future<void> cancelCurrentOperation() async {
    await FFmpegKit.cancel();
  }

  // You can add methods to get media information if needed
  Future<MediaInformationSession?> getMediaInformationSession(
    String filePath,
  ) async {
    return await FFprobeKit.getMediaInformation(filePath);
  }
}
