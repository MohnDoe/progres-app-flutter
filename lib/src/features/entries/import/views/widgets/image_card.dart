import 'package:flutter/material.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class ImageCard extends StatefulWidget {
  const ImageCard({super.key, required this.picture, required this.date});

  final ProgressPicture picture;
  final DateTime date;

  @override
  State<ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  ProgressEntryType? selectedType;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.file(widget.picture.file, width: 50),
        SegmentedButton(
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
          ),
          emptySelectionAllowed: false,
          showSelectedIcon: false,
          segments: ProgressEntryType.values
              .map(
                (entryType) => ButtonSegment(
                  value: entryType,
                  // label: Text(entryType.name),
                  icon: ProgressEntry.getIconFromType(entryType),
                ),
              )
              .toList(),
          selected: {selectedType},
          onSelectionChanged: (newSelection) {
            setState(() {
              selectedType = newSelection.first;
            });
          },
        ),
      ],
    );
  }
}
