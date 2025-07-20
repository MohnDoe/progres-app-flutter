import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
// Assuming path_provider is used by VideoService or directly for paths
// import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/video_service.dart';
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart'; // For p.join

// --- End of Placeholders ---

class _PoseMetrics {
  final img.Point midShoulder;
  final double spineLength;
  final double shoulderWidth;
  final double spineAngleDeg;
  final Map<PoseLandmarkType, PoseLandmark> allLandmarks;

  _PoseMetrics({
    required this.midShoulder,
    required this.spineLength,
    required this.shoulderWidth,
    required this.spineAngleDeg,
    required this.allLandmarks,
  });
}

class _TransformationResult {
  final img.Image image;
  final img.Point trackedPoint;

  _TransformationResult(this.image, this.trackedPoint);
}

class MLKitService {
  // Assuming this is the class name you're using
  static final Logger _logger = Logger(); // Renamed to _logger for convention
  static Stream<VideoGenerationProgress> generateAlignedImages(
    List<ProgressPicture> listPictures,
  ) async* {
    _logger.i('Preparing aligned frames with rotation and scale');
    final alignedFramesDir = await VideoService().alignedFramesDirectory;
    _logger.i('Aligned frames directory: ${alignedFramesDir.path}');

    if (await alignedFramesDir.exists()) {
      await alignedFramesDir.delete(recursive: true);
    }
    await alignedFramesDir.create();

    final poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode
            .single, // singleImage is often preferred for single frame processing
        model: PoseDetectionModel.accurate,
      ),
    );

    _PoseMetrics? targetMetrics; // Using the helper class
    int? referenceImageWidth;
    int? referenceImageHeight;

    _logger.i('Processing ${listPictures.length} pictures.');
    for (int i = 0; i < listPictures.length; i++) {
      final picture = listPictures[i];
      final imagePath = picture.file.path;
      final frameFileName = 'frame_${i.toString().padLeft(4, '0')}.jpg';
      final framePath = p.join(alignedFramesDir.path, frameFileName);

      _logger.i(
        'Processing picture ${i + 1}/${listPictures.length}: $imagePath to $frameFileName',
      );

      final Pose? pose = await _detectPoseInImage(poseDetector, imagePath);
      final originalBytes = await File(imagePath).readAsBytes(); // Read once
      img.Image? workingImage = img.decodeImage(originalBytes);

      if (workingImage == null) {
        _logger.e('Could not decode image $imagePath. Skipping.');
        yield VideoGenerationProgress(
          // Assuming error state or just skip
          VideoGenerationStep.aligningFrames, // Or a specific error step
          (i + 1) / listPictures.length,
          message: "Decode error for $imagePath",
        );
        continue;
      }

      if (pose == null) {
        await _saveProblematicFrame(
          workingImage,
          framePath,
          referenceImageWidth,
          referenceImageHeight,
        );
        yield VideoGenerationProgress(
          VideoGenerationStep.aligningFrames,
          (i + 1) / listPictures.length,
          message: "No pose in $imagePath",
          debugFilePath: framePath,
        );
        continue;
      }

      final _PoseMetrics? currentMetrics = _calculateCurrentPoseMetrics(pose);
      if (currentMetrics == null) {
        _logger.w('Could not calculate metrics for $imagePath. Saving original.');
        await _saveProblematicFrame(
          workingImage,
          framePath,
          referenceImageWidth,
          referenceImageHeight,
        );
        yield VideoGenerationProgress(
          VideoGenerationStep.aligningFrames,
          (i + 1) / listPictures.length,
          message: "Metrics error for $imagePath",
          debugFilePath: framePath,
        );
        continue;
      }

      // Draw landmarks on the working image (as per original logic)
      workingImage = _drawLandmarksOnImage(
        workingImage,
        currentMetrics.allLandmarks, // Use allLandmarks from metrics
        crossCenter: currentMetrics.midShoulder,
      );

      img.Point trackedPointInWorkingImage = currentMetrics.midShoulder;

      if (i == 0) {
        targetMetrics = currentMetrics;
        referenceImageWidth = workingImage.width;
        referenceImageHeight = workingImage.height;

        _logger.i(
          'Reference SET: Center=(${targetMetrics.midShoulder.x.toStringAsFixed(2)}, ${targetMetrics.midShoulder.y.toStringAsFixed(2)}), '
          'SpineLen=${targetMetrics.spineLength.toStringAsFixed(2)}, ShoulderWid=${targetMetrics.shoulderWidth.toStringAsFixed(2)}, '
          'SpineAngle=${targetMetrics.spineAngleDeg.toStringAsFixed(2)}deg',
        );
        await File(framePath).writeAsBytes(img.encodeJpg(workingImage));
      } else {
        if (targetMetrics == null ||
            referenceImageWidth == null ||
            referenceImageHeight == null) {
          _logger.e(
            'Reference properties not set. Cannot align $imagePath. Saving original.',
          );
          await _saveProblematicFrame(
            workingImage,
            framePath,
            referenceImageWidth,
            referenceImageHeight,
          );
          yield VideoGenerationProgress(
            VideoGenerationStep.aligningFrames,
            (i + 1) / listPictures.length,
            message: "Reference not set for $imagePath",
            debugFilePath: framePath,
          );
          continue;
        }

        final transformationResult = _applyTransformations(
          workingImage,
          targetMetrics,
          currentMetrics,
          trackedPointInWorkingImage, // This is currentMetrics.midShoulder
        );

        img.Image transformedImage = transformationResult.image;
        img.Point finalTrackedPoint = transformationResult.trackedPoint;

        img.Image finalImage = img.Image(
          width: referenceImageWidth,
          height: referenceImageHeight,
        );
        finalImage = img.fill(finalImage, color: img.ColorRgb8(0, 0, 0));

        final dstX = targetMetrics.midShoulder.x - finalTrackedPoint.x;
        final dstY = targetMetrics.midShoulder.y - finalTrackedPoint.y;

        _logger.d(
          'Compositing $imagePath: trackedMidShoulder=(${finalTrackedPoint.x.toStringAsFixed(2)}, ${finalTrackedPoint.y.toStringAsFixed(2)}), '
          'targetCrossCenter=(${targetMetrics.midShoulder.x.toStringAsFixed(2)}, ${targetMetrics.midShoulder.y.toStringAsFixed(2)}), '
          'dst=(${dstX.toStringAsFixed(2)}, ${dstY.toStringAsFixed(2)})',
        );

        finalImage = img.compositeImage(
          finalImage,
          transformedImage,
          dstX: dstX.round(),
          dstY: dstY.round(),
        );
        await File(framePath).writeAsBytes(img.encodeJpg(finalImage));
      }
      yield VideoGenerationProgress(
        VideoGenerationStep.aligningFrames,
        (i + 1) / listPictures.length,
        debugFilePath: framePath,
      );
    }

    await poseDetector.close(); // Close the detector when done
    _logger.i('Pose detector closed.');
    _logger.i('Finished generating stabilized images list with R&S attempt.');
    // Optionally yield a final completion progress update
    yield VideoGenerationProgress(
      VideoGenerationStep.aligningFrames,
      1.0,
      message: "Alignment complete",
    );
  }

  // Helper: Detect Pose
  static Future<Pose?> _detectPoseInImage(PoseDetector detector, String imagePath) async {
    final inputImageFile = InputImage.fromFile(File(imagePath));
    try {
      final List<Pose> poses = await detector.processImage(inputImageFile);
      if (poses.isNotEmpty && poses.first.landmarks.isNotEmpty) {
        return poses.first;
      }
      _logger.w('No pose or landmarks detected in $imagePath.');
    } on Exception catch (e) {
      _logger.e('Error processing image $imagePath with ML Kit: $e');
    }
    return null;
  }

  // Helper: Calculate Pose Metrics
  static _PoseMetrics? _calculateCurrentPoseMetrics(Pose pose) {
    final landmarks = pose.landmarks;
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      _logger.w('Essential landmarks missing for metric calculation.');
      return null;
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
      _logger.w('Calculated spine length is too small ($currentSpineLength).');
      return null;
    }

    final currentShoulderWidth = math.sqrt(
      math.pow(leftShoulder.x - rightShoulder.x, 2) +
          math.pow(leftShoulder.y - rightShoulder.y, 2),
    );
    if (currentShoulderWidth < 1.0) {
      _logger.w('Calculated shoulder width is too small ($currentShoulderWidth).');
      return null;
    }

    final currentSpineAngleRad = math.atan2(
      currentMidShoulderY - currentMidHipY,
      currentMidShoulderX - currentMidHipX,
    );
    final currentSpineAngleDeg = currentSpineAngleRad * (180 / math.pi);

    return _PoseMetrics(
      midShoulder: currentMidShoulderPt,
      spineLength: currentSpineLength,
      shoulderWidth: currentShoulderWidth,
      spineAngleDeg: currentSpineAngleDeg,
      allLandmarks: landmarks,
    );
  }

  // Helper: Image Transformation (Scale & Rotate)
  static _TransformationResult _applyTransformations(
    img.Image currentImage,
    _PoseMetrics targetMetrics,
    _PoseMetrics currentMetrics,
    img.Point pointToTrack, // This is currentMetrics.midShoulder initially
  ) {
    img.Image workingImage = currentImage; // Operate on this
    double trackedX = pointToTrack.x.toDouble();
    double trackedY = pointToTrack.y.toDouble();

    // --- 1. SCALING ---
    double scaleFactorSpine = targetMetrics.spineLength / currentMetrics.spineLength;
    double scaleFactorShoulder =
        targetMetrics.shoulderWidth / currentMetrics.shoulderWidth;
    double overallScaleFactor = scaleFactorShoulder; // As per original logic

    if ((overallScaleFactor - 1.0).abs() > 0.01) {
      _logger.d('Scaling by ${overallScaleFactor.toStringAsFixed(3)}');
      int newWidth = (workingImage.width * overallScaleFactor).round();
      int newHeight = (workingImage.height * overallScaleFactor).round();

      if (newWidth > 0 && newHeight > 0) {
        trackedX *= overallScaleFactor;
        trackedY *= overallScaleFactor;
        workingImage = img.copyResize(
          workingImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      } else {
        _logger.w("Invalid scale dimensions. Skipping scale.");
      }
    }

    // --- 2. ROTATION ---
    double angleDifferenceDeg =
        targetMetrics.spineAngleDeg - currentMetrics.spineAngleDeg;
    if (angleDifferenceDeg.abs() > 0.5) {
      _logger.d('Rotating by ${angleDifferenceDeg.toStringAsFixed(2)} deg');
      final imageCenterX = workingImage.width / 2.0;
      final imageCenterY = workingImage.height / 2.0;

      double pX = trackedX - imageCenterX;
      double pY = trackedY - imageCenterY;

      double angleRad = angleDifferenceDeg * (math.pi / 180.0);
      double cosA = math.cos(angleRad);
      double sinA = math.sin(angleRad);
      double pRotX = pX * cosA - pY * sinA;
      double pRotY = pX * sinA + pY * cosA;

      trackedX = pRotX + imageCenterX;
      trackedY = pRotY + imageCenterY;

      workingImage = img.copyRotate(
        workingImage,
        angle: angleDifferenceDeg,
        interpolation: img.Interpolation.linear,
      );
    }
    return _TransformationResult(workingImage, img.Point(trackedX, trackedY));
  }

  // Helper: Save Problematic Frame (original or centered on canvas)
  static Future<void> _saveProblematicFrame(
    img.Image imageToSave,
    String framePath,
    int? referenceWidth,
    int? referenceHeight,
  ) async {
    img.Image outputImage = imageToSave;
    if (referenceWidth != null &&
        referenceHeight != null &&
        (imageToSave.width != referenceWidth || imageToSave.height != referenceHeight)) {
      final canvas = img.Image(width: referenceWidth, height: referenceHeight);
      img.fill(canvas, color: img.ColorRgb8(0, 0, 0)); // Black background
      img.compositeImage(
        canvas,
        imageToSave,
        dstX: (referenceWidth - imageToSave.width) ~/ 2,
        dstY: (referenceHeight - imageToSave.height) ~/ 2,
      );
      outputImage = canvas;
    }
    await File(framePath).writeAsBytes(img.encodeJpg(outputImage));
    _logger.i('Saved problematic/original frame to $framePath');
  }

  // --- Drawing Helper (Kept from original, avoiding drawStar) ---
  static img.Image _drawLandmarksOnImage(
    img.Image image,
    Map<PoseLandmarkType, PoseLandmark> landmarks, {
    img.Point? crossCenter,
  }) {
    img.Image newImage = img.Image.from(image); // Create a copy to draw on

    // Draw all landmarks as small circles/pixels
    landmarks.forEach((type, landmark) {
      if (landmark.x.round() >= 0 &&
          landmark.x.round() < newImage.width &&
          landmark.y.round() >= 0 &&
          landmark.y.round() < newImage.height) {
        img.fillCircle(
          newImage,
          x: landmark.x.round(),
          y: landmark.y.round(),
          radius: 3,
          color: img.ColorRgb8(255, 0, 0),
        );
      }
    });

    // Draw the crossCenter if provided (e.g., a slightly larger circle)
    if (crossCenter != null) {
      if (crossCenter.x.round() >= 0 &&
          crossCenter.x.round() < newImage.width &&
          crossCenter.y.round() >= 0 &&
          crossCenter.y.round() < newImage.height) {
        img.fillCircle(
          newImage,
          x: crossCenter.x.round(),
          y: crossCenter.y.round(),
          radius: 6,
          color: img.ColorRgb8(0, 0, 255),
        );
      }
    }
    // Draw spine and shoulder lines
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

      // Simple bounds check before drawing lines
      bool linePointsValid(num x1, num y1, num x2, num y2) {
        return x1.round() >= 0 &&
            x1.round() < newImage.width &&
            y1.round() >= 0 &&
            y1.round() < newImage.height &&
            x2.round() >= 0 &&
            x2.round() < newImage.width &&
            y2.round() >= 0 &&
            y2.round() < newImage.height;
      }

      if (linePointsValid(
        leftShoulder.x,
        leftShoulder.y,
        rightShoulder.x,
        rightShoulder.y,
      )) {
        img.drawLine(
          newImage,
          x1: leftShoulder.x.round(),
          y1: leftShoulder.y.round(),
          x2: rightShoulder.x.round(),
          y2: rightShoulder.y.round(),
          color: img.ColorRgb8(0, 255, 0),
          thickness: 2,
        );
      }
      if (linePointsValid(midHipX, midHipY, midShoulderX, midShoulderY)) {
        img.drawLine(
          newImage,
          x1: midHipX.round(),
          y1: midHipY.round(),
          x2: midShoulderX.round(),
          y2: midShoulderY.round(),
          color: img.ColorRgb8(0, 255, 255),
          thickness: 2,
        );
      }
    }
    return newImage;
  }
}
