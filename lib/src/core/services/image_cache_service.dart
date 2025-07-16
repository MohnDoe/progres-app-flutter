import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class ImageCacheService {
  static Future<void> evictPictures(
    List<ProgressPicture> picturesToEvict,
  ) async {
    for (final fileToEvict in picturesToEvict) {
      final imageProvider = FileImage(fileToEvict.file);
      final bool evicted = await PaintingBinding.instance.imageCache.evict(
        imageProvider,
      );
      if (evicted) {
        print("Evicted from cache: ${fileToEvict.file.path}");
      } else {
        print("Not in cache or evict failed for: ${fileToEvict.file.path}");
      }
    }
  }
}
