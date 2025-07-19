import 'dart:io';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:logger/logger.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/video_service.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart';

class MLKitService {
  static Stream<VideoGenerationProgress> generateAlignedImages(
    List<ProgressPicture> listPictures,
  ) async* {
    Logger().i('Preparing aligned frames');
    final alignedFramesDir = await VideoService().alignedFramesDirectory;
    final poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      ),
    );

    img.Point? targetCenter;

    Logger().i('Aligned frames directory: ${alignedFramesDir.path}');

    if (!await alignedFramesDir.exists()) {
      await alignedFramesDir.create();
      Logger().i('Created aligned frames directory: ${alignedFramesDir.path}');
    }
    Logger().i('Processing ${listPictures.length} pictures.');
    for (int i = 0; i < listPictures.length; i++) {
      final picture = listPictures[i];
      final imagePath = picture.file.path;

      final framePath = p.join(
        alignedFramesDir.path,
        'frame_${i.toString().padLeft(4, '0')}.jpg',
      );

      Logger().i(
        'Processing picture ${i + 1}/${listPictures.length}: $imagePath',
      );
      Logger().i('Output frame path: $framePath');

      final image = InputImage.fromFile(picture.file);
      final poses = await poseDetector.processImage(image);

      if (poses.isEmpty) {
        Logger().w('No poses detected in $imagePath. Skipping.');
        continue;
      }
      Logger().i('Detected ${poses.length} poses in $imagePath.');
      final pose = poses.first;

      // Use shoulders and hips as stable reference points
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;

      Logger().d('Landmarks for $imagePath:');
      Logger().d('  Left Shoulder: (${leftShoulder.x}, ${leftShoulder.y})');
      Logger().d('  Right Shoulder: (${rightShoulder.x}, ${rightShoulder.y})');
      Logger().d('  Left Hip: (${leftHip.x}, ${leftHip.y})');
      Logger().d('  Right Hip: (${rightHip.x}, ${rightHip.y})');

      // Calculate the center of the torso
      final currentCenterX =
          (leftShoulder.x + rightShoulder.x + leftHip.x + rightHip.x) / 4;
      final currentCenterY =
          (leftShoulder.y + rightShoulder.y + leftHip.y + rightHip.y) / 4;
      final currentCenter = img.Point(currentCenterX, currentCenterY);
      Logger().d(
        'Current center for $imagePath: ($currentCenterX, $currentCenterY)',
      );

      // Use the first frame's center as the target for all others
      if (targetCenter == null) {
        targetCenter = currentCenter;
        Logger().i(
          'Target center established from first frame: ($currentCenterX, $currentCenterY)',
        );
      }

      // Calculate the shift needed to align the current frame
      final dx = targetCenter.x - currentCenter.x;
      final dy = targetCenter.y - currentCenter.y;
      Logger().d('Calculated shift for $imagePath: dx=$dx, dy=$dy');
      Logger().d('Target center: (${targetCenter.x}, ${targetCenter.y})');
      Logger().d('Current center: (${currentCenter.x}, ${currentCenter.y})');

      // --- Use the 'image' package to transform the frame ---
      final originalBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(originalBytes)!;

      // Create a new blank image (canvas) and paste the original image
      // at the shifted position. This effectively centers the body.
      final transformedImage = img.Image(
        width: originalImage.width,
        height: originalImage.height,
      );
      img.compositeImage(
        transformedImage,
        originalImage,
        dstX: dx.toInt(),
        dstY: dy.toInt(),
      );

      // Save the new, aligned frame
      await File(framePath).writeAsBytes(img.encodeJpg(transformedImage));
      Logger().i('Saved aligned frame to $framePath');

      yield VideoGenerationProgress(
        VideoGenerationStep.aligningFrames,
        (i + 1) / listPictures.length,
      );
    }

    poseDetector.close();
    Logger().i('Pose detector closed.');
    Logger().i('Finished generating stabilized images list.');
  }
}
