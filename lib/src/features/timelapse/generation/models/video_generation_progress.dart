enum VideoGenerationStep {
  preparingFrames,
  analyzing,
  stabilizing,
  done,
}

class VideoGenerationProgress {
  final VideoGenerationStep step;
  final double progress;
  final String? videoPath;

  VideoGenerationProgress(this.step, this.progress, {this.videoPath});
}