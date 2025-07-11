import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/features/timelapse/_shared/domain/entities/timelapse_config.dart';

abstract class TimelapseLocalDatasource {
  Future<List<File>> getStoredImageFiles(TimelapseViewType viewType);
  // Add methods for managing temporary files if needed here,
  // though FfmpegService might handle its own temp image prep directly.
}

class TimelapseLocalDatasourceImpl implements TimelapseLocalDatasource {
  // This is a placeholder. You need to implement the actual logic
  // to find and list your user's stored images based on viewType.
  // This might involve querying a local database, or scanning a specific directory structure.
  @override
  Future<List<File>> getStoredImageFiles(TimelapseViewType viewType) async {
    // Example: Assuming images are stored in app's documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    String subFolderName;
    switch (viewType) {
      case TimelapseViewType.front:
        subFolderName = 'front_images';
        break;
      case TimelapseViewType.side:
        subFolderName = 'side_images';
        break;
      case TimelapseViewType.back:
        subFolderName = 'back_images';
        break;
    }
    final viewSpecificDir = Directory(p.join(appDocDir.path, subFolderName));

    if (!await viewSpecificDir.exists()) {
      return []; // No images for this view
    }

    final List<File> imageFiles = [];
    await for (final entity in viewSpecificDir.list()) {
      if (entity is File &&
          (entity.path.endsWith('.jpg') || entity.path.endsWith('.png'))) {
        // You might want to sort these by date if not already named sequentially
        imageFiles.add(entity);
      }
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
