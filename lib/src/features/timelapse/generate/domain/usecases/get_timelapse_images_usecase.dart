import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:progres/src/core/errors/failures.dart';
import 'package:progres/src/features/timelapse/_shared/domain/entities/timelapse_config.dart';
import 'package:progres/src/features/timelapse/generate/domain/repositories/timelapse_repository.dart';

import 'usecase.dart';

class GetTimelapseImagesUsecase
    implements Usecase<List<File>, GetTimelapseImagesParams> {
  final TimelapseRepository repository;

  GetTimelapseImagesUsecase(this.repository);

  @override
  Future<Either<Failure, List<File>>> call(
    GetTimelapseImagesParams params,
  ) async {
    return await repository.getAvailableImages(params.viewType);
  }
}

class GetTimelapseImagesParams {
  // Equatable
  final TimelapseViewType viewType;

  GetTimelapseImagesParams({required this.viewType});
  // @override List<Object> get props => [viewType];
}
