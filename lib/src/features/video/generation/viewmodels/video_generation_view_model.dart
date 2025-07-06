import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/services/video_service.dart';

class VideoGenerationViewModel extends StateNotifier<AsyncValue<String>> {
  VideoGenerationViewModel() : super(const AsyncValue.loading()) {
    createVideo();
  }

  Future<void> createVideo() async {
    state = const AsyncValue.loading();
    try {
      final stabilizedVideoPath = await VideoService().createVideo();
      state = AsyncValue.data(stabilizedVideoPath);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final videoGenerationViewModelProvider =
    StateNotifierProvider<VideoGenerationViewModel, AsyncValue<String>>((ref) {
      return VideoGenerationViewModel();
    });
