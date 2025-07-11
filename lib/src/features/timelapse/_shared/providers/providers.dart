import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/timelapse/_shared/notifiers/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/_shared/notifiers/timelapse_state.dart';
import 'package:progres/src/features/timelapse/_shared/services/ffmpeg_service.dart';
import 'package:progres/src/features/timelapse/generate/data/datasources/timelapse_local_datasource.dart';
import 'package:progres/src/features/timelapse/generate/data/repositories/timelapse_repository_impl.dart';
import 'package:progres/src/features/timelapse/generate/domain/repositories/timelapse_repository.dart';
import 'package:progres/src/features/timelapse/generate/domain/usecases/cancel_timelapse_usecase.dart';
import 'package:progres/src/features/timelapse/generate/domain/usecases/generate_timelapse_usecase.dart';
import 'package:progres/src/features/timelapse/generate/domain/usecases/get_timelapse_images_usecase.dart';

// --- Data Layer Providers ---
final ffmpegServiceProvider = Provider<FfmpegService>((ref) {
  return FfmpegService();
});

final timelapseLocalDatasourceProvider = Provider<TimelapseLocalDatasource>((
  ref,
) {
  return TimelapseLocalDatasourceImpl();
});

final timelapseRepositoryProvider = Provider<TimelapseRepository>((ref) {
  return TimelapseRepositoryImpl(
    localDatasource: ref.watch(timelapseLocalDatasourceProvider),
    ffmpegService: ref.watch(ffmpegServiceProvider),
  );
});

// --- Domain Layer (Usecase) Providers ---
final getTimelapseImagesUsecaseProvider = Provider<GetTimelapseImagesUsecase>((
  ref,
) {
  return GetTimelapseImagesUsecase(ref.watch(timelapseRepositoryProvider));
});

final generateTimelapseUsecaseProvider = Provider<GenerateTimelapseUsecase>((
  ref,
) {
  return GenerateTimelapseUsecase(ref.watch(timelapseRepositoryProvider));
});

final cancelTimelapseUsecaseProvider = Provider<CancelTimelapseUsecase>((ref) {
  return CancelTimelapseUsecase(ref.watch(timelapseRepositoryProvider));
});

// --- Presentation Layer (StateNotifier) Provider ---
final timelapseNotifierProvider =
    StateNotifierProvider<TimelapseNotifier, TimelapseState>((ref) {
      return TimelapseNotifier(
        getTimelapseImagesUsecase: ref.watch(getTimelapseImagesUsecaseProvider),
        generateTimelapseUsecase: ref.watch(generateTimelapseUsecaseProvider),
        cancelTimelapseUsecase: ref.watch(cancelTimelapseUsecaseProvider),
      );
    });
