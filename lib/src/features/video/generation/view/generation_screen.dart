import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/video/generation/models/video_generation_progress.dart';
import 'package:progres/src/features/video/generation/viewmodels/video_generation_view_model.dart';
import 'package:progres/src/features/video/player/view/video_player_screen.dart';

class GenerationScreen extends ConsumerWidget {
  const GenerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generationState = ref.watch(videoGenerationViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Generating Video')),
      body: Center(
        child: generationState.when(
          data: (progress) {
            if (progress.step == VideoGenerationStep.done) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        VideoPlayerScreen(videoPath: progress.videoPath!),
                  ),
                );
              });
              return const CircularProgressIndicator();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinearProgressIndicator(value: progress.progress),
                const SizedBox(height: 16),
                Text(_getStepText(progress.step)),
              ],
            );
          },
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  String _getStepText(VideoGenerationStep step) {
    switch (step) {
      case VideoGenerationStep.preparingFrames:
        return 'Collecting entries';
      case VideoGenerationStep.analyzing:
        return 'Analyzing Video';
      case VideoGenerationStep.stabilizing:
        return 'Stabilizing Video';
      case VideoGenerationStep.done:
        return 'Done';
    }
  }
}
