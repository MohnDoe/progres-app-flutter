import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/ui/widgets/picture_rectangle.dart';

class PictureDisplay extends StatelessWidget {
  const PictureDisplay({
    super.key,
    required this.picture,
    this.highlight = false,
    this.width = double.infinity,
    this.borderRadius = 80,
  });

  final ProgressPicture? picture;
  final bool highlight;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return PictureRectangle(
      picture,
      highlight: highlight,
      width: width,
      height: double.infinity,
      borderRadius: borderRadius,
      emptyWidget: Center(
        child: Text(
          "No picture.",
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}
