// lib/features/timelapse/presentation/notifiers/timelapse_notifier.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/errors/failures.dart';
import 'package:progres/src/features/timelapse/domain/entities/timelapse_config.dart';
import 'package:progres/src/features/timelapse/domain/usecases/generate_timelapse_usecase.dart';
import 'package:progres/src/features/timelapse/domain/usecases/get_timelapse_images_usecase.dart';
import 'package:progres/src/features/timelapse/presentation/notifiers/timelapse_state.dart';

class TimelapseNotifier extends StateNotifier<TimelapseState> {
  final GetTimelapseImagesUsecase _getTimelapseImagesUsecase;
  final GenerateTimelapseUsecase _generateTimelapseUsecase;
  final CancelTimelapseUsecase _cancelTimelapseUsecase;

  TimelapseNotifier({
    required GetTimelapseImagesUsecase getTimelapseImagesUsecase,
    required GenerateTimelapseUsecase generateTimelapseUsecase,
    required CancelTimelapseUsecase cancelTimelapseUsecase,
  }) : _getTimelapseImagesUsecase = getTimelapseImagesUsecase,
       _generateTimelapseUsecase = generateTimelapseUsecase,
       _cancelTimelapseUsecase = cancelTimelapseUsecase,
       super(const TimelapseState()) {
    // Initial state
    // Initialize with a default view type or load last used
    // This could also be a method called from the UI when the screen loads
    _updateInitialConfig(TimelapseViewType.front);
  }

  void _updateInitialConfig(TimelapseViewType initialView) {
    state = state.copyWith(
      currentConfig: state.currentConfig.copyWith(viewType: initialView),
    );
  }

  Future<void> loadImagesForView(TimelapseViewType viewType) async {
    state = state.copyWith(
      status: TimelapseStatus.loadingImages,
      currentConfig: state.currentConfig.copyWith(viewType: viewType),
      clearFailure: true,
    );
    final result = await _getTimelapseImagesUsecase(
      GetTimelapseImagesParams(viewType: viewType),
    );
    result.fold(
      (failure) => state = state.copyWith(
        status: TimelapseStatus.error,
        failure: failure,
      ),
      (images) => state = state.copyWith(
        status: TimelapseStatus.imagesLoaded,
        availableImages: images,
        selectedImages: [],
      ), // Reset selected images
    );
  }

  void toggleImageSelection(File imageFile) {
    final newSelectedImages = List<File>.from(state.selectedImages);
    if (newSelectedImages.contains(imageFile)) {
      newSelectedImages.remove(imageFile);
    } else {
      newSelectedImages.add(imageFile);
    }
    state = state.copyWith(selectedImages: newSelectedImages);
  }

  void updateConfig({
    int? fps,
    bool? enableStabilization,
    int? vidstabShakiness,
    int? vidstabAccuracy,
    double? vidstabZoom,
    int? vidstabSmoothing,
  }) {
    state = state.copyWith(
      currentConfig: state.currentConfig.copyWith(
        fps: fps ?? state.currentConfig.fps,
        enableStabilization:
            enableStabilization ?? state.currentConfig.enableStabilization,
        vidstabShakiness:
            vidstabShakiness ?? state.currentConfig.vidstabShakiness,
        vidstabAccuracy: vidstabAccuracy ?? state.currentConfig.vidstabAccuracy,
        vidstabZoom: vidstabZoom ?? state.currentConfig.vidstabZoom,
        vidstabSmoothing:
            vidstabSmoothing ?? state.currentConfig.vidstabSmoothing,
      ),
    );
  }

  Future<void> startTimelapseGeneration() async {
    if (state.selectedImages.isEmpty) {
      state = state.copyWith(
        status: TimelapseStatus.error,
        failure: const ImageSelectionFailure("Please select images first."),
      );
      return;
    }

    final configWithSelectedImages = state.currentConfig.copyWith(
      sourceImageFiles: state.selectedImages,
    );
    state = state.copyWith(
      status: TimelapseStatus.processing,
      currentConfig: configWithSelectedImages,
      processingMessage: "Preparing timelapse...",
      clearFailure: true,
    );

    // You can update processingMessage more granularly if FFmpegService provides callbacks
    // For example:
    // state = state.copyWith(processingMessage: "Analyzing motion (1/2)...");
    // FfmpegService.setProgressCallback((progressMessage) => state = state.copyWith(processingMessage: progressMessage));
    // This part requires FfmpegService to be able to report progress back.

    final result = await _generateTimelapseUsecase(configWithSelectedImages);

    result.fold(
      (failure) {
        // Check if the failure is due to cancellation
        if (failure is FfmpegProcessingFailure &&
            (failure.ffmpegLogs?.contains("Received stop signal") ??
                false || failure.ffmpegLogs!.contains("Exiting normally") ??
                false &&
                    failure.returnCode !=
                        0) // Some FFmpeg versions might output this on cancel
            ) {
          state = state.copyWith(
            status: TimelapseStatus.cancelled,
            failure: failure, // Keep failure to show logs if needed
            processingMessage: "Timelapse generation cancelled.",
            clearProcessingMessage: false, // Don't clear this specific message
          );
        } else {
          state = state.copyWith(
            status: TimelapseStatus.error,
            failure: failure,
            clearProcessingMessage: true,
          );
        }
      },
      (videoPath) => state = state.copyWith(
        status: TimelapseStatus.success,
        generatedVideoPath: videoPath,
        clearProcessingMessage: true,
      ),
    );
  }

  Future<void> cancelGeneration() async {
    if (state.status == TimelapseStatus.processing) {
      print("Notifier: Attempting to cancel FFmpeg operation.");
      // For immediate UI feedback:
      state = state.copyWith(processingMessage: "Cancellation requested...");
      await _cancelTimelapseUsecase();
      // The state update to "cancelled" will happen when the generateTimelapseUsecase result is processed.
    }
  }

  void resetToInitialForView() {
    // Resets selections and status but keeps the current view type and its loaded available images
    state = TimelapseState(
      currentConfig: state.currentConfig.copyWith(sourceImageFiles: []),
      // Clear selected for config
      availableImages: state.availableImages,
      // Keep loaded available images
      status: TimelapseStatus.imagesLoaded, // Go back to images loaded state
    );
  }
}
