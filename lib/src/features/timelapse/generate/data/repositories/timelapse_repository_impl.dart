import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/errors/failures.dart';
import 'package:progres/src/features/timelapse/_shared/domain/entities/timelapse_config.dart';
import 'package:progres/src/features/timelapse/_shared/services/ffmpeg_service.dart';
import 'package:progres/src/features/timelapse/generate/data/datasources/timelapse_local_datasource.dart';
import 'package:progres/src/features/timelapse/generate/domain/repositories/timelapse_repository.dart';

class TimelapseRepositoryImpl implements TimelapseRepository {
  final TimelapseLocalDatasource localDatasource;
  final FfmpegService ffmpegService;

  TimelapseRepositoryImpl({
    required this.localDatasource,
    required this.ffmpegService,
  });

  @override
  Future<Either<Failure, List<File>>> getAvailableImages(
    ProgressEntryType viewType,
  ) async {
    try {
      final imageFiles = await localDatasource.getStoredImageFiles(viewType);
      if (imageFiles.isEmpty) {
        return Left(
          ImageSelectionFailure("No images found for ${viewType.name} view."),
        );
      }
      return Right(imageFiles);
    } catch (e) {
      return Left(
        FileOperationFailure("Failed to retrieve images: ${e.toString()}"),
      );
    }
  }

  @override
  Future<Either<Failure, String>> generateTimelapse(
    TimelapseConfig config,
  ) async {
    try {
      if (config.sourceImageFiles.isEmpty) {
        return Left(ImageSelectionFailure("No images selected for timelapse."));
      }

      final String videoOutputName =
          "timelapse_${config.viewType.name}_${DateTime.now().millisecondsSinceEpoch}.mp4";
      final String transformsFileName =
          "transforms_${config.viewType.name}.trf"; // Unique per view if needed

      if (config.enableStabilization) {
        // --- Stabilization Pass ---
        print("Starting VidStab Detect Pass...");
        final detectResult = await ffmpegService.runVidstabDetectPass(
          imageFiles: config.sourceImageFiles,
          transformsFileName: transformsFileName,
          fps: config.fps,
          shakiness: config.vidstabShakiness ?? 5,
          accuracy: config.vidstabAccuracy ?? 9,
        );

        if (!detectResult.isSuccess || detectResult.outputPath == null) {
          return Left(
            FfmpegProcessingFailure(
              "VidStab detection failed.",
              returnCode: detectResult.returnCode,
              ffmpegLogs: detectResult.logs,
            ),
          );
        }
        print(
          "VidStab Detect Pass complete. Transforms: ${detectResult.outputPath}",
        );

        print("Starting VidStab Transform Pass...");
        // Important: Get the original temp image sub-directory name if FfmpegService needs it.
        // For simplicity, FfmpegService handles its temp image dir internally now.
        final transformResult = await ffmpegService.runVidstabTransformPass(
          imageFiles: config.sourceImageFiles,
          // FFmpeg needs access to images again
          transformsFilePath: detectResult.outputPath!,
          outputVideoName: videoOutputName,
          fps: config.fps,
          zoom: config.vidstabZoom ?? 0,
          smoothing: config.vidstabSmoothing ?? 10,
          // tempImageSubDirForTransform:
          //     "vidstab_detect_images", // If detect pass images are reused
        );

        if (!transformResult.isSuccess || transformResult.outputPath == null) {
          for (final log in (transformResult.logs ?? "").split("\n")) {
            print("FFmpeg Log: $log");
          }
          return Left(
            FfmpegProcessingFailure(
              "VidStab transformation failed.",
              returnCode: transformResult.returnCode,
              ffmpegLogs: transformResult.logs,
            ),
          );
        }
        print(
          "VidStab Transform Pass complete. Video: ${transformResult.outputPath}",
        );
        return Right(transformResult.outputPath!);
      } else {
        // --- Simple Timelapse (No Stabilization) ---
        print("Starting Simple Timelapse generation...");
        final result = await ffmpegService.generateSimpleTimelapse(
          imageFiles: config.sourceImageFiles,
          outputVideoName: videoOutputName,
          fps: config.fps,
        );

        if (!result.isSuccess || result.outputPath == null) {
          return Left(
            FfmpegProcessingFailure(
              "Simple timelapse generation failed.",
              returnCode: result.returnCode,
              ffmpegLogs: result.logs,
            ),
          );
        }
        print(
          "Simple Timelapse generation complete. Video: ${result.outputPath}",
        );
        return Right(result.outputPath!);
      }
    } catch (e) {
      return Left(
        FfmpegProcessingFailure(
          "An unexpected error occurred during timelapse generation: ${e.toString()}",
        ),
      );
    }
  }

  @override
  Future<void> cancelTimelapseGeneration() async {
    await ffmpegService.cancelCurrentOperation();
  }
}
