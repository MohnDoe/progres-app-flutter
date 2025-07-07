import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class PictureGrid extends StatefulWidget {
  const PictureGrid({super.key, required this.pictures});

  final List<ProgressPicture> pictures;

  @override
  State<PictureGrid> createState() => _PictureGridState();
}

class _PictureGridState extends State<PictureGrid> {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: widget.pictures
          .map(
            (ProgressPicture picture) => Ink.image(
              image: FileImage(picture.file),
              fit: BoxFit.cover,
              child: InkWell(
                onTap: () {
                  /* ... */
                },
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Text(
                      DateFormat.yMMMd().format(picture.date),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
