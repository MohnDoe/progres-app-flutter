import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class DetectedLandmark {
  final PoseLandmarkType type; // Or your own enum if abstracting further
  final double x;
  final double y;
  final double likelihood;
  DetectedLandmark({
    required this.type,
    required this.x,
    required this.y,
    required this.likelihood,
  });
}

class DetectedPose {
  final List<DetectedLandmark> landmarks;
  DetectedPose({required this.landmarks});
}
