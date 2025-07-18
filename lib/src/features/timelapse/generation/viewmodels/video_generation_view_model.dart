import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/services/video_service.dart';
import 'package:progres/src/features/timelapse/generation/models/video_generation_progress.dart';

final videoGenerationViewModelProvider =
    StreamProvider<VideoGenerationProgress>((ref) {
      return VideoService().createVideo(ProgressEntryType.front, 10);
    });
