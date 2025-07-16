import 'dart:io';

import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class PictureRectangle extends StatefulWidget {
  const PictureRectangle(
    this.picture, {
    super.key,
    this.onTap,
    required this.width,
    required this.height,
    required this.borderRadius,
    this.emptyWidget = const Placeholder(),
    this.highlight = false,
    this.highlightWidth = 4,
    this.highlightColor = Colors.white,
  });

  final ProgressPicture? picture;
  final void Function()? onTap;
  final double width;
  final double height;
  final double borderRadius;

  final bool highlight;
  final double highlightWidth;
  final Color highlightColor;

  final Widget emptyWidget;

  @override
  State<PictureRectangle> createState() => _PictureRectangleState();
}

class _PictureRectangleState extends State<PictureRectangle> {
  @override
  Widget build(BuildContext context) {
    final ProgressPicture? picture = widget.picture;
    final File? file = picture?.file;

    return SizedBox(
      width: widget.width,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            ClipPath(
              clipBehavior: Clip.antiAlias,
              clipper: ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(widget.borderRadius),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: InkWell(
                  onTap: widget.onTap,
                  child: picture != null
                      ? Image.file(
                          key: ValueKey(
                            "${widget.key.toString()}_${file!.lastModifiedSync().millisecondsSinceEpoch}",
                          ),
                          file,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : widget.emptyWidget,
                ),
              ),
            ),
            if (widget.highlight)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: ShapeDecoration(
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(widget.borderRadius),
                      ),
                      side: BorderSide(
                        width: widget.highlightWidth,
                        color: widget.highlightColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
