import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/services/video_service.dart';
import 'package:progres/src/features/timelapse/_shared/repositories/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart';

// final videoGenerationViewModelProvider = StreamProvider<VideoGenerationProgress>((ref) {
//   return VideoService().createVideo(ProgressEntryType.front, 7);
// });

final videoGenerationViewModelProvider = StreamProvider.autoDispose
    .family<VideoGenerationProgress, Timelapse>((ref, configuration) {
      final videoService = VideoService();
      return videoService.createVideo(
        configuration,
        ref.read(timelapseProvider.notifier).videoFilename,
      );
    });
