enum TimelapseStatus {
  idle,
  selectingImages,
  detectingPoses,
  calculatingTransforms,
  processingFrames,
  encodingVideo,
  success,
  error,
}

class TimelapseGenerationState {
  TimelapseGenerationState({
    required this.status,
    required this.progress,
    this.message,
    this.videoPath,
    this.errorMessage,
  });

  final TimelapseStatus status;
  final double progress; // 0.0 to 1.0
  final String? message; // e.g., "Processing image 5 of 20"
  final String? videoPath; // Path to the generated video on success

  final String? errorMessage;

  // Constructor, copyWith, initial factory
}
