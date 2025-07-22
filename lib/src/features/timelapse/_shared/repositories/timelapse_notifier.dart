import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/services/video_service.dart';
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart';

enum Quality { sd, fhd, uhd }

class Timelapse {
  Timelapse({
    required this.type,
    required this.from,
    required this.to,
    this.quality = Quality.fhd,
    this.fps = 10,
    this.stabilization = false,
    this.watermark = true,
    this.showDateOnTimelapse = true,
    this.generationProgress = const VideoGenerationProgress(VideoGenerationStep.none, 0),
    this.entries = const [],
  });

  final ProgressEntryType type;

  final DateTime from;
  final DateTime to;

  final Quality quality;
  final int fps;
  final bool stabilization;
  final bool watermark;
  final bool showDateOnTimelapse;
  final List<ProgressEntry> entries;

  VideoGenerationProgress generationProgress;

  Timelapse copyWith({
    ProgressEntryType? type,
    DateTime? from,
    DateTime? to,
    Quality? quality,
    int? fps,
    bool? stabilization,
    bool? watermark,
    bool? showDateOnTimelapse,
    VideoGenerationProgress? generationProgress,
    String? filePath,
    List<ProgressEntry>? entries,
  }) {
    return Timelapse(
      type: type ?? this.type,
      from: from ?? this.from,
      to: to ?? this.to,
      quality: quality ?? this.quality,
      fps: fps ?? this.fps,
      stabilization: stabilization ?? this.stabilization,
      watermark: watermark ?? this.watermark,
      showDateOnTimelapse: showDateOnTimelapse ?? this.showDateOnTimelapse,
      generationProgress: generationProgress ?? this.generationProgress,
      entries: entries ?? this.entries,
    );
  }

  @override
  String toString() {
    return 'Timelapse('
        'type: $type, '
        'from: $from, '
        'to: $to, '
        'quality: $quality, '
        'fps: $fps, '
        'stabilization: $stabilization, '
        'watermark: $watermark, '
        'showDateOnTimelapse: $showDateOnTimelapse, '
        'generationProgress: $generationProgress'
        ')';
  }
}

Timelapse defaultTimelapse() {
  return Timelapse(
    type: ProgressEntryType.front,
    from: DateTime.now().subtract(const Duration(days: 526)),
    to: DateTime.now(),
  );
}

class TimelapseNotifier extends Notifier<Timelapse> {
  TimelapseNotifier() : super();

  @override
  Timelapse build() {
    return defaultTimelapse();
  }

  String get videoFilename {
    return "timelapse_${state.type.name}_${state.from.millisecondsSinceEpoch}_${state.to.millisecondsSinceEpoch}_${state.quality.name}_${state.fps}fps.mp4";
  }

  Future<String> get videoPath async {
    return VideoService().getVideoPath(videoFilename);
  }

  void setFps(int fps) {
    state = state.copyWith(fps: fps);
  }

  void setQuality(Quality quality) {
    state = state.copyWith(quality: quality);
  }

  void setStabilization(bool stabilization) {
    state = state.copyWith(stabilization: stabilization);
  }

  void setWatermark(bool watermark) {
    state = state.copyWith(watermark: watermark);
  }

  void setShowDateOnTimelapse(bool showDateOnTimelapse) {
    state = state.copyWith(showDateOnTimelapse: showDateOnTimelapse);
  }

  void setType(ProgressEntryType type) {
    state = state.copyWith(type: type);
  }

  void setFrom(DateTime from) {
    state = state.copyWith(from: from);
  }

  void setTo(DateTime to) {
    state = state.copyWith(to: to);
  }

  void setFilePath(String filePath) {
    state = state.copyWith(filePath: filePath);
  }

  void setEntries(List<ProgressEntry> entries) {
    state = state.copyWith(entries: entries);
  }
}

final timelapseProvider = NotifierProvider<TimelapseNotifier, Timelapse>(() {
  return TimelapseNotifier();
});
