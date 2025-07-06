import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/video/generation/viewmodels/video_generation_view_model.dart';

class GenerationScreen extends ConsumerStatefulWidget {
  const GenerationScreen({super.key});

  @override
  ConsumerState createState() => _GenerationScreenState();
}

class _GenerationScreenState extends ConsumerState<GenerationScreen> {
  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(videoGenerationViewModelProvider);

    return Container(
      child: generationState.when(
        data: (path) => Text(path),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
