import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/timelapse/data/datasources/timelapse_local_datasource.dart';
import 'package:progres/src/features/timelapse/data/repositories/timelapse_repository_impl.dart';
import 'package:progres/src/features/timelapse/domain/repositories/timelapse_repository.dart';
import 'package:progres/src/features/timelapse/domain/usecases/cancel_timelapse_usecase.dart';
import 'package:progres/src/features/timelapse/domain/usecases/generate_timelapse_usecase.dart';
import 'package:progres/src/features/timelapse/domain/usecases/get_timelapse_images_usecase.dart';
import 'package:progres/src/features/timelapse/presentation/notifiers/timelapse_notifier.dart';
import 'package:progres/src/features/timelapse/presentation/notifiers/timelapse_state.dart';
import 'package:progres/src/features/timelapse/services/ffmpeg_service.dart';

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
