import 'dart:io';
import 'package:dartz/dartz.dart'; // For Either
import 'package:progres/src/core/errors/failures.dart';
import 'package:progres/src/features/timelapse/_shared/domain/entities/timelapse_config.dart';

abstract class TimelapseRepository {
  /// Fetches the list of image files available for timelapse creation for a given view.
  /// This is specific to how you store and identify your user's daily photos.
  Future<Either<Failure, List<File>>> getAvailableImages(
    TimelapseViewType viewType,
  );

  /// Generates the timelapse video based on the provided configuration.
  /// Returns the path to the generated video file on success.
  Future<Either<Failure, String>> generateTimelapse(TimelapseConfig config);

  /// Cancels any ongoing FFmpeg operation.
  Future<void> cancelTimelapseGeneration();
}
