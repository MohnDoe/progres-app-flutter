import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// General Failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

// Timelapse Specific Failures
class FfmpegProcessingFailure extends Failure {
  final int? returnCode;
  final String? ffmpegLogs;

  const FfmpegProcessingFailure(
    super.message, {
    this.returnCode,
    this.ffmpegLogs,
  });

  @override
  List<Object> get props => [message, returnCode ?? 0, ffmpegLogs ?? ''];
}

class ImageSelectionFailure extends Failure {
  const ImageSelectionFailure(super.message);
}

class FileOperationFailure extends Failure {
  const FileOperationFailure(super.message);
}
