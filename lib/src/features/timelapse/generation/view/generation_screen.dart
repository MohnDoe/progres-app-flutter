import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart';
import 'package:progres/src/features/timelapse/generation/viewmodels/video_generation_view_model.dart';
import 'package:progres/src/features/timelapse/player/view/video_player_screen.dart';

class GenerationScreen extends ConsumerWidget {
  static const String name = 'generation';
  static const String path = '/generation';
  static const String pathParams = '/:type/:from/:to';

  final ProgressEntryType type;
  final DateTime from;
  final DateTime to;

  const GenerationScreen({
    super.key,
    required this.from,
    required this.to,
    required this.type,
  });

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
                context.pushReplacementNamed(
                  VideoPlayerScreen.name,
                  pathParameters: {
                    'from': from.millisecondsSinceEpoch.toString(),
                    'to': to.millisecondsSinceEpoch.toString(),
                    'type': type.name,
                  },
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
                const SizedBox(height: 16),
                if (progress.message != null) Text(progress.message!),
                const SizedBox(height: 16),

                if (progress.debugFilePath != null)
                  Image.file(File(progress.debugFilePath!), width: 200),
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
      case VideoGenerationStep.none:
        return 'Starting';
      case VideoGenerationStep.preparingFrames:
        return 'Collecting entries';
      case VideoGenerationStep.generating:
        return 'Generating video';
      case VideoGenerationStep.aligningFrames:
        return 'Aligning frames';
      case VideoGenerationStep.analyzing:
        return 'Analyzing pictures';
      case VideoGenerationStep.stabilizing:
        return 'Stabilizing video';
      case VideoGenerationStep.done:
        return 'Done';
    }
  }
}
