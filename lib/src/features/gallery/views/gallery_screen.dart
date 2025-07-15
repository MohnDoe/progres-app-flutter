import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';

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
  // Declare them as late instance variables, initialized in initState
  late ProgressEntry
  _selectedEntry; // Use an underscore to denote internal state
  late ProgressEntryType _selectedType;

  @override
  void initState() {
    super.initState();
    // Initialize from widget properties when the state is first created
    _selectedEntry = widget.currentEntry;
    _selectedType = widget.entryType;
  }

  @override
  Widget build(BuildContext context) {
    List<ProgressEntry> entries = ref
        .watch(progressEntriesRepositoryProvider)
        .orderedEntries
        .where((ProgressEntry entry) => entry.pictures[_selectedType] != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        // SIDE SELECTION
        title: SegmentedButton(
          showSelectedIcon: false,
          segments: ProgressEntryType.values
              .map(
                (ProgressEntryType type) => ButtonSegment(
                  value: type,
                  label: Text(type.name),
                  enabled: _selectedEntry.pictures[type] != null,
                ),
              )
              .toList(),
          selected: {_selectedType},
          onSelectionChanged: (value) {
            setState(() {
              _selectedType = value.first;
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
          // DATE ENTRY
          Text(
            DateFormat.yMMMd().format(_selectedEntry.date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          // BIG PICTURE
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
                    child: _selectedEntry.pictures[_selectedType] != null
                        ? Image.file(
                            _selectedEntry.pictures[_selectedType]!.file,
                            fit: BoxFit.cover,
                          )
                        : SizedBox(width: 240),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.separated(
              reverse: true,
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              itemBuilder: (ctx, index) => ClipPath(
                clipBehavior: Clip.antiAlias,
                clipper: ShapeBorderClipper(
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedEntry = entries[index];
                    });
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      entries[index].pictures[_selectedType]!.file,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              separatorBuilder: (ctx, index) => const SizedBox(width: 8),
            ),
          ),
        ],
      ),
    );
  }
}
