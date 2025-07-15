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
  final CarouselController _carouselController = CarouselController(
    // TODO: get correct initial item
    initialItem: 1,
  );
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
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<ProgressEntry> entries = ref
        .watch(progressEntriesRepositoryProvider)
        .orderedEntries
        .where((ProgressEntry entry) => entry.pictures[_selectedType] != null)
        .toList();

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipPath(
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
                  const SizedBox(height: 16),
                  SegmentedButton(
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
                ],
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: CarouselView(
              controller: _carouselController,
              itemExtent: 80,
              shrinkExtent: 16,
              itemSnapping: true,

              onTap: (index) {
                setState(() {
                  _selectedEntry = entries[index];
                  _carouselController.animateToItem(index);
                });
              },
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              reverse: true,
              children: entries
                  .map(
                    (e) => Stack(
                      children: [
                        Image.file(
                          width: 80,
                          height: double.infinity,
                          e.pictures[_selectedType]!.file,
                          fit: BoxFit.cover,
                        ),
                        e == _selectedEntry
                            ? Container(
                                decoration: ShapeDecoration(
                                  shape: ContinuousRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                    side: BorderSide(
                                      width: 4,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(),
    );
  }
}
