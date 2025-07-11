// lib/features/timelapse/presentation/notifiers/timelapse_state.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/errors/failures.dart';
import 'package:progres/src/features/timelapse/_shared/domain/entities/timelapse_config.dart';

enum TimelapseStatus {
  initial, // Initial state, nothing loaded
  loadingImages, // Fetching available images
  imagesLoaded, // Images ready for selection
  configuring, // User is setting options (FPS, stabilization)
  processing, // FFmpeg is running
  success, // Timelapse generated successfully
  error, // An error occurred
  cancelled, // User cancelled
}

class TimelapseState extends Equatable {
  final TimelapseStatus status;
  final List<File> availableImages; // All images for the selected view
  final List<File> selectedImages; // Images user has chosen for the timelapse
  final TimelapseConfig
  currentConfig; // Holds current FPS, stabilization settings
  final String? generatedVideoPath;
  final Failure? failure;
  final String?
  processingMessage; // e.g., "Analyzing motion...", "Applying stabilization..."

  const TimelapseState({
    this.status = TimelapseStatus.initial,
    this.availableImages = const [],
    this.selectedImages = const [],
    this.currentConfig = const TimelapseConfig(
      sourceImageFiles: [],
      viewType: ProgressEntryType.front,
    ), // Default
    this.generatedVideoPath,
    this.failure,
    this.processingMessage,
  });

  TimelapseState copyWith({
    TimelapseStatus? status,
    List<File>? availableImages,
    List<File>? selectedImages,
    TimelapseConfig? currentConfig,
    String? generatedVideoPath,
    Failure? failure,
    bool clearFailure = false, // Helper to explicitly clear failure
    String? processingMessage,
    bool clearProcessingMessage = false,
  }) {
    return TimelapseState(
      status: status ?? this.status,
      availableImages: availableImages ?? this.availableImages,
      selectedImages: selectedImages ?? this.selectedImages,
      currentConfig: currentConfig ?? this.currentConfig,
      generatedVideoPath: generatedVideoPath ?? this.generatedVideoPath,
      failure: clearFailure ? null : failure ?? this.failure,
      processingMessage: clearProcessingMessage
          ? null
          : processingMessage ?? this.processingMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    availableImages,
    selectedImages,
    currentConfig,
    generatedVideoPath,
    failure,
    processingMessage,
  ];
}
