import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({
    super.key,
    required this.currentEntry,
    this.entryType = ProgressEntryType.front,
  });

  final ProgressEntry currentEntry;
  final ProgressEntryType entryType;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    ProgressEntryType selectedType = widget.entryType;
    ProgressEntry entry = widget.currentEntry;

    return Scaffold(
      appBar: AppBar(
        title: SegmentedButton(
          showSelectedIcon: false,
          segments: ProgressEntryType.values
              .map(
                (ProgressEntryType type) => ButtonSegment(
                  value: type,
                  label: Text(type.name),
                  enabled: entry.pictures[type] != null,
                ),
              )
              .toList(),
          selected: {selectedType},
          onSelectionChanged: (value) {
            setState(() {
              selectedType = value.first;
            });
          },
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            DateFormat.yMMMd().format(entry.date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: ClipPath(
                clipBehavior: Clip.antiAlias,
                clipper: ShapeBorderClipper(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(80)),
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    child: entry.pictures[selectedType] != null
                        ? Image.file(
                            entry.pictures[selectedType]!.file,
                            fit: BoxFit.cover,
                          )
                        : SizedBox(width: 240),
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
