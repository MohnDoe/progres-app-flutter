import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/errors/failures.dart';
import 'package:progres/src/features/timelapse/_shared/domain/entities/timelapse_config.dart';
import 'package:progres/src/features/timelapse/_shared/notifiers/timelapse_state.dart';
import 'package:progres/src/features/timelapse/_shared/providers/providers.dart';

class TimelapseCreationScreen extends ConsumerWidget {
  const TimelapseCreationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelapseState = ref.watch(timelapseNotifierProvider);
    final timelapseNotifier = ref.read(timelapseNotifierProvider.notifier);

    // Example: Initial load of images for a default view
    // This could also be triggered by a dropdown or button in the UI
    // Be careful not to call this repeatedly in build if not needed.
    // Consider using a flag or checking state.status.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (timelapseState.status == TimelapseStatus.initial) {
        timelapseNotifier.loadImagesForView(
          TimelapseViewType.front,
        ); // Default view
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Timelapse'),
        actions: [
          if (timelapseState.status == TimelapseStatus.processing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => timelapseNotifier.cancelGeneration(),
              tooltip: "Cancel Processing",
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- View Type Selector ---
            DropdownButton<TimelapseViewType>(
              value: timelapseState.currentConfig.viewType,
              items: TimelapseViewType.values
                  .map(
                    (view) => DropdownMenuItem(
                      value: view,
                      child: Text(view.name.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (TimelapseViewType? newView) {
                if (newView != null) {
                  timelapseNotifier.loadImagesForView(newView);
                }
              },
            ),
            const SizedBox(height: 16),

            // --- Status Display ---
            if (timelapseState.status == TimelapseStatus.loadingImages)
              const Center(child: CircularProgressIndicator()),
            if (timelapseState.status == TimelapseStatus.processing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    // Or a more detailed progress bar
                    const SizedBox(height: 8),
                    Text(
                      timelapseState.processingMessage ??
                          "Processing... please wait.",
                    ),
                  ],
                ),
              ),
            if (timelapseState.failure != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Error: ${timelapseState.failure!.message}'
                  '${timelapseState.failure is FfmpegProcessingFailure ? "\nFFmpeg Logs: ${(timelapseState.failure as FfmpegProcessingFailure).ffmpegLogs?.substring(0, (timelapseState.failure as FfmpegProcessingFailure).ffmpegLogs!.length > 500 ? 500 : (timelapseState.failure as FfmpegProcessingFailure).ffmpegLogs!.length) ?? 'N/A'}" : ""}',

                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (timelapseState.status == TimelapseStatus.success &&
                timelapseState.generatedVideoPath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Text(
                      'Timelapse generated successfully!',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                    Text(
                      'Video saved at: ${timelapseState.generatedVideoPath}',
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement play video (e.g., using video_player)
                        print(
                          "Play video: ${timelapseState.generatedVideoPath}",
                        );
                      },
                      child: const Text("Play Video"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement share video (e.g., using share_plus)
                        print(
                          "Share video: ${timelapseState.generatedVideoPath}",
                        );
                      },
                      child: const Text("Share Video"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement save to gallery (e.g., using gallery_saver)
                        print(
                          "Save to gallery: ${timelapseState.generatedVideoPath}",
                        );
                      },
                      child: const Text("Save to Gallery"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        timelapseNotifier.resetToInitialForView();
                      },
                      child: const Text("Create Another"),
                    ),
                  ],
                ),
              ),

            // --- Image Selection (Placeholder UI) ---
            if (timelapseState.status == TimelapseStatus.imagesLoaded ||
                timelapseState.status == TimelapseStatus.configuring) ...[
              const Text(
                'Available Images:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (timelapseState.availableImages.isEmpty)
                const Text('No images found for this view.'),
              SizedBox(
                height: 150, // Adjust as needed
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: timelapseState.availableImages.length,
                  itemBuilder: (context, index) {
                    final imageFile = timelapseState.availableImages[index];
                    final isSelected = timelapseState.selectedImages.contains(
                      imageFile,
                    );
                    return GestureDetector(
                      onTap: () =>
                          timelapseNotifier.toggleImageSelection(imageFile),
                      child: Card(
                        color: isSelected ? Colors.blue.withOpacity(0.3) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            children: [
                              Image.file(
                                imageFile,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Image ${index + 1}",
                                style: const TextStyle(fontSize: 10),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Text('Selected Images: ${timelapseState.selectedImages.length}'),
              const SizedBox(height: 20),

              // --- Timelapse Options (Placeholder UI) ---
              const Text(
                'Timelapse Options:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextFormField(
                initialValue: timelapseState.currentConfig.fps.toString(),
                decoration: const InputDecoration(
                  labelText: 'FPS (Frames Per Second)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final fps = int.tryParse(value);
                  if (fps != null) {
                    timelapseNotifier.updateConfig(fps: fps);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Enable Stabilization (VidStab)'),
                value: timelapseState.currentConfig.enableStabilization,
                onChanged: (bool value) {
                  timelapseNotifier.updateConfig(enableStabilization: value);
                },
              ),
              if (timelapseState.currentConfig.enableStabilization) ...[
                TextFormField(
                  initialValue:
                      (timelapseState.currentConfig.vidstabShakiness ?? 5)
                          .toString(),
                  decoration: const InputDecoration(
                    labelText: 'VidStab Shakiness (1-10)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => timelapseNotifier.updateConfig(
                    vidstabShakiness: int.tryParse(value),
                  ),
                ),
                TextFormField(
                  initialValue:
                      (timelapseState.currentConfig.vidstabSmoothing ?? 10)
                          .toString(),
                  decoration: const InputDecoration(
                    labelText: 'VidStab Smoothing (e.g., 10-30)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => timelapseNotifier.updateConfig(
                    vidstabSmoothing: int.tryParse(value),
                  ),
                ),
                TextFormField(
                  initialValue: (timelapseState.currentConfig.vidstabZoom ?? 0)
                      .toString(),
                  decoration: const InputDecoration(
                    labelText: 'VidStab Zoom % (0 for auto)',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => timelapseNotifier.updateConfig(
                    vidstabZoom: double.tryParse(value),
                  ),
                ),
              ],
              const SizedBox(height: 30),

              // --- Action Button ---
              if (timelapseState.status != TimelapseStatus.processing &&
                  timelapseState.status != TimelapseStatus.success &&
                  timelapseState.status != TimelapseStatus.loadingImages)
                Center(
                  child: ElevatedButton(
                    onPressed: timelapseState.selectedImages.length < 2
                        ? null // Disable if not enough images
                        : () => timelapseNotifier.startTimelapseGeneration(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('Generate Timelapse'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
