import 'package:dartz/dartz.dart';
import 'package:progres/src/core/errors/failures.dart';
import 'package:progres/src/features/timelapse/domain/entities/timelapse_config.dart';
import 'package:progres/src/features/timelapse/domain/repositories/timelapse_repository.dart';
import 'package:progres/src/features/timelapse/domain/usecases/usecase.dart';

class GenerateTimelapseUsecase implements Usecase<String, TimelapseConfig> {
  final TimelapseRepository repository;

  GenerateTimelapseUsecase(this.repository);

  @override
  Future<Either<Failure, String>> call(TimelapseConfig params) async {
    // You could add more business logic here if needed before calling the repository
    if (params.sourceImageFiles.length < 2) {
      return Left(
        ImageSelectionFailure(
          "At least two images are required for a timelapse.",
        ),
      );
    }
    return await repository.generateTimelapse(params);
  }
}
