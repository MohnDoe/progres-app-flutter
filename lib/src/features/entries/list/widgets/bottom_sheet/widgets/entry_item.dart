import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/widgets/today_entry_highlight.dart';
import 'package:progres/src/features/gallery/views/gallery_screen.dart';

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
  void _openPictureViewer(ProgressEntryType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            GalleryScreen(currentEntry: widget.entry, entryType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("EntryItem: rebuilding");
    print(widget.entry.date);
    print(widget.entry.lastModifiedTimestamp);
    return widget.highlight
        ? TodayEntryHighlight(
            key: ValueKey(widget.entry.lastModifiedTimestamp),
            widget.entry,
            onTapEdit: widget.onTapEdit,
          )
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                EntryImages(
                  key: ValueKey(widget.entry.lastModifiedTimestamp),
                  lastUpdated: widget.entry.lastModifiedTimestamp,
                  pictures: widget.entry.pictures,
                  onPictureTap: (type) => _openPictureViewer(type),
                ),
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
  const EntryImages({
    super.key,
    required this.pictures,
    required this.onPictureTap,
    required this.lastUpdated,
  });

  final Map<ProgressEntryType, ProgressPicture> pictures;
  final int lastUpdated;

  final void Function(ProgressEntryType type) onPictureTap;

  @override
  Widget build(BuildContext context) {
    print("EntryImages: rebuilding");
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
                    ? InkWell(
                        onTap: () => onPictureTap(entryType),
                        child: Image.memory(
                          pictures[entryType]!.file.readAsBytesSync(),
                          key: ValueKey(
                            '${pictures[entryType]!.file.path}_$lastUpdated',
                          ),
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.error),
                        ),
                      )
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }
}
