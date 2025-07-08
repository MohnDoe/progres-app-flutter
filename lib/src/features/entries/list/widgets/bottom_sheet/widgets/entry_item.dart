import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:vector_math/vector_math_64.dart';

class EntryItem extends StatefulWidget {
  const EntryItem({super.key, required this.entry});
  final ProgressEntry entry;

  @override
  State<EntryItem> createState() => _EntryItemState();
}

class _EntryItemState extends State<EntryItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          EntryImages(pictures: widget.entry.pictures),
          const SizedBox(width: 8),
          Text(DateFormat.yMMMd().format(widget.entry.date)),
          Spacer(),
          IconButton(onPressed: () {}, icon: Icon(Icons.edit, size: 16)),
        ],
      ),
    );
  }
}

class EntryImages extends StatelessWidget {
  const EntryImages({super.key, required this.pictures});

  final Map<ProgressEntryType, ProgressPicture> pictures;

  @override
  Widget build(BuildContext context) {
    var displayedTypes = ProgressEntryType.values
        // .where((ProgressEntryType entryType) => pictures[entryType] != null)
        .toList();
    return Row(
      children: displayedTypes
          .map(
            (ProgressEntryType entryType) => Container(
              transform: Matrix4.translation(
                Vector3(
                  (-8 * displayedTypes.indexOf(entryType).toDouble()),
                  0,
                  0,
                ),
              ),
              child: ClipOval(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
                  child: pictures[entryType] != null
                      ? Image.file(
                          pictures[entryType]!.file,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
