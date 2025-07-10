import 'package:flutter_riverpod/flutter_riverpod.dart';

class FFmpegVideoEncodingService {}

final videoEncodingServiceProvider = Provider<FFmpegVideoEncodingService>((
  ref,
) {
  return FFmpegVideoEncodingService(); // Your implementation
});
