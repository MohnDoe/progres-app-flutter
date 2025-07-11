// lib/features/timelapse/domain/entities/timelapse_config.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';

class TimelapseConfig extends Equatable {
  final List<File> sourceImageFiles; // The actual selected image files
  final ProgressEntryType viewType;
  final int fps;
  final bool enableStabilization;

  // Stabilization specific parameters (if enabled)
  final int? vidstabShakiness;
  final int? vidstabAccuracy;
  final double? vidstabZoom; // Percentage for manual zoom, 0 for optzoom
  final int? vidstabSmoothing;

  const TimelapseConfig({
    required this.sourceImageFiles,
    required this.viewType,
    this.fps = 10,
    this.enableStabilization = false,
    this.vidstabShakiness,
    this.vidstabAccuracy,
    this.vidstabZoom,
    this.vidstabSmoothing,
  });

  @override
  List<Object?> get props => [
    sourceImageFiles,
    viewType,
    fps,
    enableStabilization,
    vidstabShakiness,
    vidstabAccuracy,
    vidstabZoom,
    vidstabSmoothing,
  ];

  TimelapseConfig copyWith({
    List<File>? sourceImageFiles,
    ProgressEntryType? viewType,
    int? fps,
    bool? enableStabilization,
    int? vidstabShakiness,
    int? vidstabAccuracy,
    double? vidstabZoom,
    int? vidstabSmoothing,
  }) {
    return TimelapseConfig(
      sourceImageFiles: sourceImageFiles ?? this.sourceImageFiles,
      viewType: viewType ?? this.viewType,
      fps: fps ?? this.fps,
      enableStabilization: enableStabilization ?? this.enableStabilization,
      vidstabShakiness: vidstabShakiness ?? this.vidstabShakiness,
      vidstabAccuracy: vidstabAccuracy ?? this.vidstabAccuracy,
      vidstabZoom: vidstabZoom ?? this.vidstabZoom,
      vidstabSmoothing: vidstabSmoothing ?? this.vidstabSmoothing,
    );
  }
}
