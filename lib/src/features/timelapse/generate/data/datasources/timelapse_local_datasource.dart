import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/services/file_service.dart';
import 'package:progres/src/features/timelapse/_shared/domain/entities/timelapse_config.dart';

abstract class TimelapseLocalDatasource {
  Future<List<File>> getStoredImageFiles(ProgressEntryType viewType);
}

class TimelapseLocalDatasourceImpl implements TimelapseLocalDatasource {
  // This is a placeholder. You need to implement the actual logic
  // to find and list your user's stored images based on viewType.
  // This might involve querying a local database, or scanning a specific directory structure.
  @override
  Future<List<File>> getStoredImageFiles(ProgressEntryType viewType) async {
    final List<Directory> entriesDirectories = await PicturesFileService()
        .listEntriesDirectory();

    final List<File> imageFiles = [];

    for (final entryDirectory in entriesDirectories) {
      final file = await PicturesFileService.getFileFromEntryDirectory(
        entryDirectory,
        viewType,
      );

      if (file != null) imageFiles.add(file);
    }
    // IMPORTANT: Ensure images are sorted chronologically for the timelapse!
    // This might involve parsing filenames if they contain timestamps, or using file modified dates.
    // For simplicity, let's assume they are added in order or you sort them here.
    imageFiles.sort(
      (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
    ); // Example sort

    return imageFiles;
  }
}
