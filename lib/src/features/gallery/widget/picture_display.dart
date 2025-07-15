import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class PictureDisplay extends StatelessWidget {
  const PictureDisplay({
    super.key,
    required this.picture,
    this.highlight = false,
    this.width = double.infinity,
    this.borderRadius = 80,
  });

  final ProgressPicture picture;
  final bool highlight;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          ClipPath(
            clipBehavior: Clip.antiAlias,
            clipper: ShapeBorderClipper(
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
              ),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.file(picture.file, fit: BoxFit.cover),
            ),
          ),
          if (highlight)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: ShapeDecoration(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(borderRadius),
                    ),
                    side: BorderSide(
                      width: 4,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
