import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class PictureRectangle extends StatelessWidget {
  const PictureRectangle(
    this.picture, {
    super.key,
    required this.onTap,
    required this.width,
    required this.height,
    required this.borderRadius,
    this.emptyWidget = const Placeholder(),
  });

  final ProgressPicture? picture;
  final void Function() onTap;
  final double width;
  final double height;
  final double borderRadius;

  final Widget emptyWidget;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipBehavior: Clip.antiAlias,
      clipper: ShapeBorderClipper(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: InkWell(
          onTap: onTap,
          child: picture != null
              ? Image.file(
                  picture!.file,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : emptyWidget,
        ),
      ),
    );
  }
}
