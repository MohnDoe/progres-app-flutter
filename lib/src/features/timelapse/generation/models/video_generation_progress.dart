enum VideoGenerationStep {
  none,
  preparingFrames,
  aligningFrames,
  generating,
  analyzing,
  stabilizing,
  done,
}

class VideoGenerationProgress {
  const VideoGenerationProgress(
    this.step,
    this.progress, {
    this.videoPath,
    this.message,
    this.debugFilePath,
  });

  final VideoGenerationStep step;
  final double progress;
  final String? videoPath;
  final String? message;

  final String? debugFilePath;
}
