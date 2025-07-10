import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImageProcessingService {}

final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return ImageProcessingService();
});
