import 'dart:io';
import 'dart:math' as math;

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
    Logger().i('Preparing aligned frames with rotation and scale');
    final alignedFramesDir = await VideoService().alignedFramesDirectory;
    Logger().i('Aligned frames directory: ${alignedFramesDir.path}');

    if (await alignedFramesDir.exists()) {
      await alignedFramesDir.delete(recursive: true);
    }
    await alignedFramesDir.create();

    final poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      ),
    );

    // --- Reference Pose Properties ---
    img.Point? targetCenter; // Target center for final translation
    double? targetPoseHeight; // For scaling
    double? targetShoulderWidth; // For width scaling
    double? targetHipWidth; // For width scaling
    double? targetPoseAngle; // For rotation
    int? referenceImageWidth;
    int? referenceImageHeight;

    Logger().i('Processing ${listPictures.length} pictures.');
    for (int i = 0; i < listPictures.length; i++) {
      final picture = listPictures[i];
      final imagePath = picture.file.path;
      final frameFileName = 'frame_${i.toString().padLeft(4, '0')}.jpg';
      final framePath = p.join(alignedFramesDir.path, frameFileName);

      Logger().i(
        'Processing picture ${i + 1}/${listPictures.length}: $imagePath to $frameFileName',
      );

      final inputImageFile = InputImage.fromFile(picture.file);

      List<Pose> poses = [];

      try {
        poses = await poseDetector.processImage(inputImageFile);
      } on Exception catch (e) {
        Logger().e('Error processing image $imagePath: $e');
      }

      if (poses.isEmpty) {
        Logger().w('No poses detected in $imagePath. Saving original.');
        // Optionally copy the original image if no pose is found, or skip
        final originalBytes = await File(imagePath).readAsBytes();
        await File(framePath).writeAsBytes(originalBytes);
        yield VideoGenerationProgress(
          VideoGenerationStep.aligningFrames,
          (i + 1) / listPictures.length,
        );
        continue;
      }
      final pose = poses.first;

      // Key landmarks for torso and head
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
      final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
      final rightEar = pose.landmarks[PoseLandmarkType.rightEar];

      // Estimate head center (e.g., average of eyes and mouth, or approximate from nose)
      // For simplicity, using nose as a proxy for head position for angle calculation.
      // More robust: use multiple head landmarks if available and consistently detected.
      final nose = pose.landmarks[PoseLandmarkType.nose]!;
      double headCenterX = nose.x;
      double headCenterY = nose.y;

      if (leftEar != null && rightEar != null) {
        headCenterX = (nose.x + leftEar.x + rightEar.x) / 3;
        headCenterY = (nose.y + leftEar.y + rightEar.y) / 3;
      }

      // --- Calculate current pose properties ---
      final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
      final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;

      final midHipX = (leftHip.x + rightHip.x) / 2;
      final midHipY = (leftHip.y + rightHip.y) / 2;

      final currentTorsoCenterX = (midShoulderX + midHipX) / 2;
      final currentTorsoCenterY = (midShoulderY + midHipY) / 2;

      final currentCenterPt = img.Point(currentTorsoCenterX, currentTorsoCenterY);
      // Calculate pose height (distance between mid-shoulder and mid-hip)
      final currentPoseHeight = math.sqrt(
        math.pow(midShoulderX - midHipX, 2) + math.pow(midShoulderY - midHipY, 2),
      );
      // Calculate current shoulder width and hip width
      final currentShoulderWidth = math.sqrt(
        math.pow(leftShoulder.x - rightShoulder.x, 2) +
            math.pow(leftShoulder.y - rightShoulder.y, 2),
      );
      final currentHipWidth = math.sqrt(
        math.pow(leftHip.x - rightHip.x, 2) + math.pow(leftHip.y - rightHip.y, 2),
      );

      // Calculate pose angle using a line from the middle of the hips to the head center.
      // Angle with respect to positive X-axis, then convert to degrees
      final currentPoseAngleRad = math.atan2(
        headCenterY - midHipY, // Rise (Y difference between head and mid-hips)
        headCenterX - midHipX, // Run (X difference between head and mid-hips)
        // Ensure the angle points upwards, typically by ensuring atan2 input reflects
        // the vector from hips (lower point) to head (upper point).
        // If midHipY is typically larger than headCenterY (image coordinates),
        // then (headCenterY - midHipY) will be negative for an upright pose.
      );

      final currentPoseAngleDeg = currentPoseAngleRad * (180 / math.pi);

      // --- Load original image using 'image' package ---
      final originalBytes = await File(imagePath).readAsBytes();
      img.Image? originalImage = img.decodeImage(originalBytes);

      if (originalImage == null) {
        Logger().e('Could not decode image $imagePath. Skipping.');
        continue;
      }

      // Draw landmarks for debugging/visualization if needed
      originalImage = _drawLandmarksOnImage(originalImage, pose.landmarks);

      originalImage = img.drawLine(
        originalImage,
        x1: leftShoulder.x.round(),
        y1: leftShoulder.y.round(),
        x2: rightShoulder.x.round(),
        y2: rightShoulder.y.round(),
        color: img.ColorRgb8(0, 255, 0), // Green for shoulder line
        thickness: 5,
      );

      // Draw the line used for pose angle calculation (mid-hip to head center)
      originalImage = img.drawLine(
        originalImage,
        x1: midHipX.round(),
        y1: midHipY.round(),
        x2: headCenterX.round(),
        y2: headCenterY.round(),
        color: img.ColorRgb8(255, 255, 0), // Yellow for pose angle line
        thickness: 6,
      );

      img.Image transformedImage = originalImage; // Start with the original

      if (targetCenter == null ||
          targetPoseHeight == null ||
          targetPoseAngle == null ||
          targetShoulderWidth == null ||
          targetHipWidth == null) {
        // This is the first image, establish it as the reference
        targetCenter = currentCenterPt;
        targetPoseHeight = currentPoseHeight;
        targetShoulderWidth = currentShoulderWidth;
        targetHipWidth = currentHipWidth;
        targetPoseAngle = currentPoseAngleDeg;
        Logger().i(
          'Reference SET: Center=(${targetCenter.x.toStringAsFixed(2)}, ${targetCenter.y.toStringAsFixed(2)}), '
          'Height=${targetPoseHeight.toStringAsFixed(2)}, ShoulderWidth=${targetShoulderWidth.toStringAsFixed(2)}, '
          'HipWidth=${targetHipWidth.toStringAsFixed(2)}, Angle=${targetPoseAngle.toStringAsFixed(2)}deg',
        );
        // The reference image itself doesn't need transformation relative to itself
      } else {
        // This block executes for i > 0 (non-reference images)
        // Ensure reference dimensions are set (should have been from i=0)
        if (referenceImageWidth == null || referenceImageHeight == null) {
          // This should ideally not happen if the first image was processed.
          // Fallback or error handling needed here. For now, log and potentially skip.
          Logger().e(
            'Reference image dimensions not set. Skipping alignment for $imagePath',
          );
          continue;
        }
        // --- Apply transformations for subsequent images ---

        // 1. SCALING
        // Height scaling based on poseHeight
        if (targetPoseHeight > 0 && currentPoseHeight > 0) {
          double scaleFactorHeight = targetPoseHeight / currentPoseHeight;
          // Limit scaling to prevent extreme distortions (e.g., max 2x zoom in or out)

          if ((scaleFactorHeight - 1.0).abs() > 0.01) {
            // Apply only if significant scale difference
            Logger().d(
              'Scaling Height by $scaleFactorHeight. TargetH: $targetPoseHeight, CurrentH: $currentPoseHeight',
            );
            transformedImage = img.copyResize(
              transformedImage,
              height: (transformedImage.height * scaleFactorHeight).round(),
              interpolation: img.Interpolation.linear, // Or linear for speed
            );
          }
        }

        // Width scaling based on shoulder and hip width (average or max, choose one strategy)
        // Using average of shoulder and hip width for overall body width scaling
        double currentAvgBodyWidth = (currentShoulderWidth + currentHipWidth) / 2;
        double targetAvgBodyWidth = (targetShoulderWidth + targetHipWidth) / 2;

        if (targetAvgBodyWidth > 0 && currentAvgBodyWidth > 0) {
          double scaleFactorWidth = targetAvgBodyWidth / currentAvgBodyWidth;
          if ((scaleFactorWidth - 1.0).abs() > 0.01) {
            Logger().d(
              'Scaling Width by $scaleFactorWidth. TargetAvgW: $targetAvgBodyWidth, CurrentAvgW: $currentAvgBodyWidth',
            );
            transformedImage = img.copyResize(
              transformedImage,
              width: (transformedImage.width * scaleFactorWidth).round(),
              interpolation: img.Interpolation.linear,
            );
            // After resizing, the effective center point's coordinates within the new image change
            // The *relative* position of the torso center within the image should be preserved.
            // However, since we are scaling THE ENTIRE IMAGE, the absolute pixel values of currentCenterPt
            // (which were from the *original* image dimensions) need to be scaled too if we were to use them
            // on this newly scaled 'transformedImage'.
            // For simplicity in this step-by-step transformation, we are applying transformations
            // globally. The key is that the *final translation* will use the targetCenter
            // from the *original reference image dimensions* and align the *final transformed image's center* to it.

            // The 'currentCenterPt' was calculated on the 'originalImage'.
            // For the purpose of being the *pivot* for rotation and translation,
            // we need its coordinates *in the context of the currently transformed image*.
            // Since scaling was applied to the whole image, the center point also scaled.
            // currentCenterPt = img.Point(currentCenterPt.x * scaleFactor, currentCenterPt.y * scaleFactor);
            // This update is complex because currentCenterPt might be used as a pivot.
            // Let's simplify: the image is scaled. The features within it are scaled.
            // The *relative* positions of landmarks are the same.
          }
        }

        // 2. ROTATION
        final angleDifferenceDeg = targetPoseAngle - currentPoseAngleDeg;
        if (angleDifferenceDeg.abs() > 0.5) {
          Logger().d(
            'Rotating by ${angleDifferenceDeg.toStringAsFixed(2)}deg. TargetA: $targetPoseAngle, CurrentA: $currentPoseAngleDeg',
          );
          // The 'image' package rotates around the center of the image.
          // For more precise body-centered rotation, we'd ideally want to rotate
          // around the 'currentCenterPt' of the body *within the current state of transformedImage*.
          // This is hard with 'copyRotate' directly if that point isn't the image center.

          // Simpler approach for now: rotate the whole image.
          // More advanced: translate body center to origin, rotate, translate back.
          transformedImage = img.copyRotate(
            transformedImage,
            angle: angleDifferenceDeg,
            interpolation: img.Interpolation.linear,
          );
        }

        // After scaling and rotating, the image dimensions and content have changed.
        // We need to re-evaluate the pose on this *partially transformed image*
        // to get the *new* currentCenter for the final translation step.
        // This is the most robust way but adds processing time.

        // --- Option B: Approximate new center (less accurate, but simpler than re-detection) ---
        // This is complex because rotation and scaling affect the coordinates.
        // The original `currentCenterPt` was in the coordinate system of `originalImage`.
        // After scaling and rotating `transformedImage`, that point is now somewhere else.
        // If we want to align to `targetCenter` (which is in the reference image's coordinate system),
        // we need to know where the body's center *is now* in the `transformedImage`.

        // For now, let's stick to the core idea:
        // The goal is that after all transformations, the body in `transformedImage`
        // should align with where the body was in the reference image if it were
        // placed at `targetCenter`.

        // The dx/dy for final compositing should be based on the *target reference dimensions*.
        // We need to figure out the offset to move `transformedImage` so its body aligns with `targetCenter`.
        // This requires knowing the new position of `currentCenterPt` within `transformedImage`.

        // This is where using an affine transformation matrix shines, as it handles all this.
        // With sequential operations in the `image` package, it's harder.

        // Let's make a simplifying assumption for the final translation:
        // The `targetCenter` is where we want the body center of the *final output image* to be.
        // The `currentCenterPt` was the body center in the *original input image*.
        // We have scaled and rotated `transformedImage`.
        // If we assume `targetCenter` is a point on a final canvas of the reference image's size,
        // and we want to place the `transformedImage` (which now has a scaled/rotated body)
        // such that its body center (which was originally `currentCenterPt`) ends up at `targetCenter`.

        // The `compositeImage` function takes dstX, dstY for the top-left of the source image.
        // We want: targetCenter.x = dstX + transformedImage.width / 2 (approx if body is centered in transformedImage)
        // We want: targetCenter.y = dstY + transformedImage.height / 2

        // This is still not quite right. The `currentCenterPt` is where the body was.
        // After scaling and rotation of the *whole image*, if those operations were
        // perfectly body-centric, the body would still be at a similar *relative* position
        // within `transformedImage`.

        // Let's refine the final translation step:
        // The `targetCenter` is the absolute coordinate from the reference frame.
        // The `currentCenterPt` is the absolute coordinate from the current original frame.
        // The offset `dx = targetCenter.x - currentCenterPt.x` and `dy = targetCenter.y - currentCenterPt.y`
        // was what we used before.
        // This offset should be applied to the `transformedImage` (which has been scaled and rotated).

        // The issue is that `dx` and `dy` are based on original image coordinates.
        // `compositeImage` applies to `transformedImage`.

        // Simplest interpretation for now for the final translation:
        // Assume `targetCenter` is the desired final position for the body's original center point.
        final dx = targetCenter.x - currentCenterPt.x; // Offset based on original centers
        final dy = targetCenter.y - currentCenterPt.y;

        Logger().d(
          'Final Translation dx=${dx.toStringAsFixed(2)}, dy=${dy.toStringAsFixed(2)}',
        );

        // Use the stored reference image dimensions for the canvas
        final int determinedCanvasWidth = referenceImageWidth;
        final int determinedCanvasHeight = referenceImageHeight;

        // This part is for i > 0
        img.Image imageToSave;

        if (i == 0) {
          // For the first frame (reference frame), no further compositing is needed.
          // transformedImage is the original image, which is already correctly sized.
          imageToSave = transformedImage;
        } else {
          // For subsequent frames, create the final canvas using reference dimensions
          // and composite the scaled/rotated 'transformedImage' onto it.

          // For subsequent frames, create the final canvas and composite the
          // scaled/rotated 'transformedImage' onto it.
          img.Image finalImage = img.Image(
            width: determinedCanvasWidth,
            height: determinedCanvasHeight,
          );

          finalImage = img.fill(
            finalImage,
            color: img.ColorRgb8(0, 0, 0),
          ); // Fill with black

          // The dx, dy calculation for translation
          final dx = targetCenter.x - currentCenterPt.x;
          final dy = targetCenter.y - currentCenterPt.y;
          Logger().d(
            'Final Translation dx=${dx.toStringAsFixed(2)}, dy=${dy.toStringAsFixed(2)} for frame $i',
          );

          imageToSave = img.compositeImage(
            finalImage,
            transformedImage, // This is the image already scaled and rotated
            dstX: dx.round(),
            dstY: dy.round(),
          );
        }
      }

      // If this is the first image, store its dimensions as reference
      if (i == 0) {
        referenceImageWidth = transformedImage.width;
        referenceImageHeight = transformedImage.height;
      }

      // Save the new, aligned frame
      await File(framePath).writeAsBytes(img.encodeJpg(transformedImage));
      Logger().i('Saved processed frame to $framePath');

      yield VideoGenerationProgress(
        VideoGenerationStep.aligningFrames,
        (i + 1) / listPictures.length,
      );
    }

    poseDetector.close();
    Logger().i('Pose detector closed.');
    Logger().i('Finished generating stabilized images list with R&S attempt.');
  }

  // Helper method to draw landmarks on the image
  static img.Image _drawLandmarksOnImage(
    img.Image image,
    Map<PoseLandmarkType, PoseLandmark> landmarks,
  ) {
    final logger = Logger();
    logger.d(
      'Drawing landmarks on image. Image dimensions: ${image.width}x${image.height}',
    );

    final paint = img.ColorRgb8(255, 0, 0); // Red color for landmarks
    const radius = 10; // Radius of the circle for each landmark

    final typesToDraw = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.nose,
    ];

    for (var type in typesToDraw) {
      final landmark = landmarks[type];
      if (landmark != null) {
        // Ensure landmarks are within image bounds before drawing
        logger.d(
          'Landmark ${type.toString()}: (${landmark.x.round()}, ${landmark.y.round()})',
        );
        if (landmark.x >= 0 &&
            landmark.x < image.width &&
            landmark.y >= 0 &&
            landmark.y < image.height) {
          image = img.fillCircle(
            image,
            x: landmark.x.round(),
            y: landmark.y.round(),
            radius: radius,
            color: paint,
          );
          logger.d('Landmark ${type.toString()} drawn.');
        } else {
          logger.w(
            'Landmark ${type.toString()} is out of bounds: (${landmark.x.round()}, ${landmark.y.round()})',
          );
        }
      } else {
        logger.w('Landmark ${type.toString()} not found.');
      }
    }
    logger.d('Finished drawing landmarks.');
    return image;
  }
}
