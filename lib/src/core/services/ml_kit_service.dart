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

    img.Point? targetCrossCenter; // Mid-shoulder of the reference pose
    double? targetSpineLength; // Mid-hip to mid-shoulder
    double? targetShoulderWidth;
    double? targetSpineAngleDeg; // Angle of the spine (mid-hip to mid-shoulder)

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

      if (poses.isEmpty || poses.first.landmarks.isEmpty) {
        Logger().w('No pose detected in $imagePath. Skipping.');
        // Optionally, save the original image or a blank frame
        final originalBytes = await File(imagePath).readAsBytes();
        img.Image? originalImage = img.decodeImage(originalBytes);
        if (originalImage != null) {
          if (referenceImageWidth != null &&
              referenceImageHeight != null &&
              (originalImage.width != referenceImageWidth ||
                  originalImage.height != referenceImageHeight)) {
            // If reference dimensions are set, create a canvas and center the image
            final canvas = img.Image(
              width: referenceImageWidth,
              height: referenceImageHeight,
            );
            img.fill(canvas, color: img.ColorRgb8(0, 0, 0)); // Black background
            img.compositeImage(
              canvas,
              originalImage,
              dstX: (referenceImageWidth - originalImage.width) ~/ 2,
              dstY: (referenceImageHeight - originalImage.height) ~/ 2,
            );
            await File(framePath).writeAsBytes(img.encodeJpg(canvas));
          } else {
            await File(framePath).writeAsBytes(img.encodeJpg(originalImage));
          }
        }
        continue;
      }

      final pose = poses.first;

      // Key landmarks for torso and head
      final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
      // final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
      // final rightEar = pose.landmarks[PoseLandmarkType.rightEar];

      if (leftShoulder == null ||
          rightShoulder == null ||
          leftHip == null ||
          rightHip == null) {
        Logger().w('Essential landmarks missing in $imagePath. Skipping.');
        continue;
      }
      final currentMidShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
      final currentMidShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final currentMidShoulderPt = img.Point(currentMidShoulderX, currentMidShoulderY);

      final currentMidHipX = (leftHip.x + rightHip.x) / 2;
      final currentMidHipY = (leftHip.y + rightHip.y) / 2;

      final currentSpineLength = math.sqrt(
        math.pow(currentMidShoulderX - currentMidHipX, 2) +
            math.pow(currentMidShoulderY - currentMidHipY, 2),
      );
      if (currentSpineLength < 1.0) {
        // Avoid division by zero or tiny values
        Logger().w('Spine length too small in $imagePath. Skipping.');
        continue;
      }

      final currentShoulderWidth = math.sqrt(
        math.pow(leftShoulder.x - rightShoulder.x, 2) +
            math.pow(leftShoulder.y - rightShoulder.y, 2),
      );
      if (currentShoulderWidth < 1.0) {
        Logger().w('Shoulder width too small in $imagePath. Skipping.');
        continue;
      }

      // Spine angle: from mid-hip (origin) to mid-shoulder (point)
      final currentSpineAngleRad = math.atan2(
        currentMidShoulderY - currentMidHipY,
        currentMidShoulderX - currentMidHipX,
      );
      final currentSpineAngleDeg = currentSpineAngleRad * (180 / math.pi);

      // --- Load original image using 'image' package ---
      final originalBytes = await File(imagePath).readAsBytes();
      img.Image? workingImage = img.decodeImage(originalBytes);

      if (workingImage == null) {
        Logger().e('Could not decode image $imagePath. Skipping.');
        continue;
      }

      workingImage = _drawLandmarksOnImage(
        workingImage,
        pose.landmarks,
        crossCenter: currentMidShoulderPt,
      );

      // --- Point to track: currentMidShoulderPt (its coordinates are relative to original image) ---
      // We need to find where this point ends up after transformations on `workingImage`.
      double trackedMidShoulderX = currentMidShoulderPt.x.toDouble();
      double trackedMidShoulderY = currentMidShoulderPt.y.toDouble();
      // These are relative to the top-left of the CURRENT `workingImage`

      // Store original dimensions for later use if needed for point transformation calculations
      final originalImageWidthForCalc = workingImage.width;
      final originalImageHeightForCalc = workingImage.height;

      if (i == 0) {
        // This is the reference image
        targetCrossCenter = currentMidShoulderPt; // Store as img.Point for consistency
        targetSpineLength = currentSpineLength;
        targetShoulderWidth = currentShoulderWidth;
        targetSpineAngleDeg = currentSpineAngleDeg;
        referenceImageWidth = workingImage.width;
        referenceImageHeight = workingImage.height;

        Logger().i(
          'Reference SET: Center=(${targetCrossCenter.x.toStringAsFixed(2)}, ${targetCrossCenter.y.toStringAsFixed(2)}), '
          'SpineLen=${targetSpineLength.toStringAsFixed(2)}, ShoulderWid=${targetShoulderWidth.toStringAsFixed(2)}, '
          'SpineAngle=${targetSpineAngleDeg.toStringAsFixed(2)}deg',
        );
        // Save the reference image as is (already on its own canvas implicitly)
        await File(framePath).writeAsBytes(img.encodeJpg(workingImage));
      } else {
        // Subsequent images: Align to reference
        if (targetCrossCenter == null ||
            targetSpineLength == null ||
            targetShoulderWidth == null ||
            targetSpineAngleDeg == null ||
            referenceImageWidth == null ||
            referenceImageHeight == null) {
          Logger().e('Reference properties not set. Cannot align $imagePath. Skipping.');

          continue;
        }

        // --- 1. SCALING ---
        // Uniform scaling based on spine length (primary) and shoulder width (secondary, if desired)
        double scaleFactorSpine = targetSpineLength! / currentSpineLength;
        double scaleFactorShoulder = targetShoulderWidth! / currentShoulderWidth;

        // Choose a single scale factor. Average can be a good compromise,
        // or prioritize one (e.g., spine length).
        // Using spine for now as it's often more stable for body size.
        double overallScaleFactor = scaleFactorSpine;
        // Or: double overallScaleFactor = (scaleFactorSpine + scaleFactorShoulder) / 2.0;

        if ((overallScaleFactor - 1.0).abs() > 0.01) {
          // Apply if significant
          Logger().d(
            'Scaling image for $imagePath by ${overallScaleFactor.toStringAsFixed(3)}',
          );
          int newWidth = (workingImage.width * overallScaleFactor).round();
          int newHeight = (workingImage.height * overallScaleFactor).round();

          if (newWidth <= 0 || newHeight <= 0) {
            Logger().w("Invalid scale dimensions for $imagePath. Skipping scale.");
          } else {
            // Update the tracked point's coordinates due to whole-image scaling
            // The scaling is applied from (0,0) of the image.
            trackedMidShoulderX *= overallScaleFactor;
            trackedMidShoulderY *= overallScaleFactor;

            workingImage = img.copyResize(
              workingImage,
              width: newWidth,
              height: newHeight,
              interpolation: img.Interpolation.linear,
            );
          }
        }

        // --- 2. ROTATION ---
        double angleDifferenceDeg = targetSpineAngleDeg! - currentSpineAngleDeg;
        // Normalize angle to be between -180 and 180 if needed, though atan2 usually handles it well.

        if (angleDifferenceDeg.abs() > 0.5) {
          // Apply if significant rotation
          Logger().d(
            'Rotating image for $imagePath by ${angleDifferenceDeg.toStringAsFixed(2)} deg',
          );

          // `copyRotate` rotates around the center of `workingImage`.
          // We need to calculate how `trackedMidShoulder` moves due to this.
          final imageCenterX = workingImage!.width / 2.0;
          final imageCenterY = workingImage.height / 2.0;

          // Translate tracked point to be relative to image center
          double pX = trackedMidShoulderX - imageCenterX;
          double pY = trackedMidShoulderY - imageCenterY;

          // Rotate the point
          double angleRad = angleDifferenceDeg * (math.pi / 180.0);
          double cosA = math.cos(angleRad);
          double sinA = math.sin(angleRad);
          double pRotX = pX * cosA - pY * sinA;
          double pRotY = pX * sinA + pY * cosA;

          // Translate point back from image center
          trackedMidShoulderX = pRotX + imageCenterX;
          trackedMidShoulderY = pRotY + imageCenterY;

          workingImage = img.copyRotate(
            workingImage,
            angle: angleDifferenceDeg,
            interpolation: img.Interpolation.linear,
          );
        }
        // --- 3. TRANSLATION (COMPOSITING) ---
        // Create the final canvas with reference dimensions
        img.Image finalImage = img.Image(
          width: referenceImageWidth,
          height: referenceImageHeight,
        );
        finalImage = img.fill(
          finalImage,
          color: img.ColorRgb8(0, 0, 0),
        ); // Black background

        // We want `trackedMidShoulder` (which is now in the coordinate system of the
        // scaled and rotated `workingImage`) to land at `targetCrossCenter`
        // (which is in the coordinate system of the reference/final image).
        final dstX = targetCrossCenter.x - trackedMidShoulderX;
        final dstY = targetCrossCenter.y - trackedMidShoulderY;

        Logger().d(
          'Compositing $imagePath: trackedMidShoulder=(${trackedMidShoulderX.toStringAsFixed(2)}, ${trackedMidShoulderY.toStringAsFixed(2)}), '
          'targetCrossCenter=(${targetCrossCenter.x.toStringAsFixed(2)}, ${targetCrossCenter.y.toStringAsFixed(2)}), '
          'dst=(${dstX.toStringAsFixed(2)}, ${dstY.toStringAsFixed(2)})',
        );

        finalImage = img.compositeImage(
          finalImage,
          workingImage,
          dstX: dstX.round(),
          dstY: dstY.round(),
        );

        await File(framePath).writeAsBytes(img.encodeJpg(finalImage));
      }
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
    Map<PoseLandmarkType, PoseLandmark> landmarks, {
    img.Point? crossCenter,
  }) {
    final logger = Logger();
    img.Image newImage = img.Image.from(image);
    logger.d(
      'Drawing landmarks on image. Image dimensions: ${image.width}x${image.height}',
    );
    if (crossCenter != null) {
      newImage = img.fillCircle(
        newImage,
        x: crossCenter.x.round(),
        y: crossCenter.y.round(),
        color: img.ColorRgb8(0, 0, 255),
        radius: 10,
      );
    }
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
          newImage = img.fillCircle(
            newImage,
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
    // Draw spine and shoulder lines based on midpoints for clarity
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];
    if (leftShoulder != null &&
        rightShoulder != null &&
        leftHip != null &&
        rightHip != null) {
      final midShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
      final midShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final midHipX = (leftHip.x + rightHip.x) / 2;
      final midHipY = (leftHip.y + rightHip.y) / 2;

      // Shoulder line
      newImage = img.drawLine(
        newImage,
        x1: leftShoulder.x.round(),
        y1: leftShoulder.y.round(),
        x2: rightShoulder.x.round(),
        y2: rightShoulder.y.round(),
        color: img.ColorRgb8(0, 255, 0),
        thickness: 3,
      );
      // Spine line
      newImage = img.drawLine(
        newImage,
        x1: midHipX.round(),
        y1: midHipY.round(),
        x2: midShoulderX.round(),
        y2: midShoulderY.round(),
        color: img.ColorRgb8(0, 255, 255),
        thickness: 3,
      );
    }
    logger.d('Finished drawing landmarks.');
    return newImage;
  }
}
