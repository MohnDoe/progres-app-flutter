import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/widgets/today_entry_highlight.dart';
import 'package:vector_math/vector_math_64.dart';

class EntryItem extends StatefulWidget {
  const EntryItem({
    super.key,
    required this.entry,
    required this.onTapEdit,
    this.highlight = false,
  });
  final ProgressEntry entry;
  final void Function() onTapEdit;
  final bool highlight;

  @override
  State<EntryItem> createState() => _EntryItemState();
}

class _EntryItemState extends State<EntryItem> {
  @override
  Widget build(BuildContext context) {
    return widget.highlight
        ? TodayEntryHighlight(widget.entry, onTapEdit: widget.onTapEdit)
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                EntryImages(pictures: widget.entry.pictures),
                Spacer(),
                Text(DateFormat.yMMMd().format(widget.entry.date)),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onTapEdit,
                  icon: Icon(Icons.edit, size: 16),
                ),
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
        .where((ProgressEntryType entryType) => pictures[entryType] != null)
        .toList();
    return Row(
      spacing: 4,
      children: displayedTypes
          .map(
            (ProgressEntryType entryType) => ClipPath(
              clipBehavior: Clip.antiAlias,
              clipper: ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: pictures[entryType] != null
                    ? Image.file(
                        pictures[entryType]!.file,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }
}
