import 'package:progres/src/features/timelapse/domain/repositories/timelapse_repository.dart';

class CancelTimelapseUsecase {
  final TimelapseRepository repository;

  CancelTimelapseUsecase(this.repository);

  Future<void> call() async {
    await repository.cancelTimelapseGeneration();
  }
}
