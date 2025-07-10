import 'package:flutter/animation.dart';

class FrameTransformParameters {
  FrameTransformParameters({
    required this.originalImagePath,
    required this.scaleFactor,
    required this.rotationAngleRadians,
    required this.translation,
  }); // or the full AffineMatrix

  final String originalImagePath;
  final double scaleFactor;
  final double rotationAngleRadians; // and pivot point

  final Offset translation;
}
