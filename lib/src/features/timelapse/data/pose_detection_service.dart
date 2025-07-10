import 'dart:io';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:progres/src/features/timelapse/domain/detected_pose.dart';

// Abstract interface (optional, but good for testing and dependency inversion)
abstract class PoseDetectionService {
  Future<DetectedPose?> detectPoseFromFile(String imagePath);
  // You could add other methods if needed, e.g., detectPoseFromBytes(Uint8List imageBytes)
  void dispose(); // Important to release resources used by the detector
}

class MLKitPoseDetectionService implements PoseDetectionService {
  final PoseDetector _poseDetector;

  // Constructor can take options if you need to customize the detector
  MLKitPoseDetectionService({PoseDetectorOptions? options})
    : _poseDetector = PoseDetector(
        options:
            options ??
            PoseDetectorOptions(
              mode: PoseDetectionMode
                  .single, // Or .streamImage if processing a live camera feed elsewhere
              model: PoseDetectionModel
                  .base, // Or .accurate for higher accuracy at the cost of speed/size
            ),
      );

  @override
  Future<DetectedPose?> detectPoseFromFile(String imagePath) async {
    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      print('MLKitPoseDetectionService: File does not exist at $imagePath');
      return null;
    }

    final InputImage inputImage = InputImage.fromFilePath(imagePath);

    try {
      final List<Pose> poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        print('MLKitPoseDetectionService: No poses detected in $imagePath');
        return null;
      }

      // For timelapse, we usually expect one person.
      // If multiple people are detected, you might want to pick the most prominent one,
      // the one closest to the center, or the largest one.
      // For simplicity, let's take the first one detected.
      final Pose firstPose = poses.first;

      // Convert ML Kit's PoseLandmark objects to your domain's DetectedLandmark objects
      final List<DetectedLandmark> detectedLandmarks = [];
      firstPose.landmarks.forEach((landmarkType, poseLandmark) {
        detectedLandmarks.add(
          DetectedLandmark(
            type:
                landmarkType, // This assumes PoseLandmarkType from ML Kit is directly usable or mapped
            x: poseLandmark.x,
            y: poseLandmark.y,
            likelihood: poseLandmark.likelihood,
          ),
        );
      });

      if (detectedLandmarks.isEmpty) {
        // This case should ideally not happen if a Pose was found,
        // but as a safeguard.
        print(
          'MLKitPoseDetectionService: Pose detected but no landmarks converted for $imagePath',
        );
        return null;
      }

      return DetectedPose(landmarks: detectedLandmarks);
    } catch (e, stackTrace) {
      print(
        'MLKitPoseDetectionService: Error processing image $imagePath - $e',
      );
      print(stackTrace);
      return null;
    }
  }

  // It's crucial to dispose of the PoseDetector when it's no longer needed
  // to release native resources.
  @override
  void dispose() {
    _poseDetector.close();
    print('MLKitPoseDetectionService: PoseDetector closed.');
  }
}
