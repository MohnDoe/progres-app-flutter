import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/timelapse/application/timelapse_state.dart';

/*
* This is the boss of the factory floor. It takes the order
* (e.g., "create a timelapse from these user entries") and manages the entire
*  production pipeline from start to finish.
* */
class TimelapseGeneratorService
    extends StateNotifier<TimelapseGenerationState> {
  final Ref _ref;

  TimelapseGeneratorService(this._ref)
    : super(
        TimelapseGenerationState(status: TimelapseStatus.idle, progress: 0),
      );
}

final timelapseGeneratorServiceProvider =
    StateNotifierProvider.autoDispose<
      TimelapseGeneratorService,
      TimelapseGenerationState
    >((ref) {
      return TimelapseGeneratorService(ref);
    });
