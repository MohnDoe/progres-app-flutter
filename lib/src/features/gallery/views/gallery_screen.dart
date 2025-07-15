import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/gallery/widget/picture_display.dart';

enum GalleryMode { display, sideBySide }

enum ActiveEntry { first, second }

enum CarouselDirection { left, right }

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({
    super.key,
    required this.currentEntry,
    this.entryType = ProgressEntryType.front,
    this.mode = GalleryMode.display,
    this.secondEntry,
  });

  final ProgressEntryType entryType;
  final ProgressEntry currentEntry;
  final ProgressEntry? secondEntry;

  final GalleryMode mode;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final CarouselController _carouselController = CarouselController(
    // TODO: get correct initial item
    initialItem: 1,
  );

  late ProgressEntry _firstEntry = widget.currentEntry;
  late ProgressEntry? _secondEntry = widget.secondEntry;
  late ProgressEntryType _selectedType = widget.entryType;
  ActiveEntry _activeEntry = ActiveEntry.first;

  late GalleryMode mode = widget.mode;

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

    int getIndexOfEntry(ProgressEntry entry, ActiveEntry activeEntry) {
      if (activeEntry == ActiveEntry.first) {
        return entries.indexOf(_firstEntry);
      } else {
        return entries.indexOf(_secondEntry!);
      }
    }

    void move(CarouselDirection direction) {
      final currentIndex = getIndexOfEntry(_firstEntry, _activeEntry);

      int newIndex = currentIndex;

      if (direction == CarouselDirection.right) {
        newIndex = max(currentIndex - 1, 0);
      } else {
        newIndex = min(currentIndex + 1, entries.length - 1);
      }
      final newEntry = entries[newIndex];

      setState(() {
        if (_activeEntry == ActiveEntry.first) {
          _firstEntry = newEntry;
        } else {
          _secondEntry = newEntry;
        }
        _carouselController.animateToItem(newIndex);
      });
    }

    bool hasPreviousEntry() {
      final index = entries.indexOf(
        _activeEntry == ActiveEntry.first ? _firstEntry : _secondEntry!,
      );
      return index < entries.length - 1;
    }

    bool hasNextEntry() {
      final index = entries.indexOf(
        _activeEntry == ActiveEntry.first ? _firstEntry : _secondEntry!,
      );
      return index > 0;
    }

    void initSideBySide() {
      if (_secondEntry == null) {
        setState(() {
          _secondEntry = _firstEntry;
        });
      }
    }

    void toggleMode() {
      setState(() {
        mode == GalleryMode.display
            ? mode = GalleryMode.sideBySide
            : mode = GalleryMode.display;

        if (mode == GalleryMode.sideBySide) {
          initSideBySide();
        } else {
          if (_activeEntry == ActiveEntry.second) {
            _firstEntry = _secondEntry!;
          }
          _activeEntry = ActiveEntry.first;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          // BIG PICTURE
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (mode == GalleryMode.display)
                    Column(
                      children: [
                        // DATE ENTRY
                        Text(
                          DateFormat.yMMMd().format(_firstEntry.date),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        PictureDisplay(
                          picture: _firstEntry.pictures[_selectedType]!,
                          highlight: false,
                        ),
                      ],
                    ),
                  if (mode == GalleryMode.sideBySide)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      spacing: 32,
                      children: [
                        Column(
                          children: [
                            Text(
                              DateFormat.yMMMd().format(_firstEntry.date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _activeEntry = ActiveEntry.first;
                                  _carouselController.animateToItem(
                                    getIndexOfEntry(
                                      _firstEntry,
                                      ActiveEntry.first,
                                    ),
                                  );
                                });
                              },
                              child: PictureDisplay(
                                picture: _firstEntry.pictures[_selectedType]!,
                                highlight: _activeEntry == ActiveEntry.first,
                                width: 200,
                                borderRadius: 64,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              DateFormat.yMMMd().format(_secondEntry!.date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _activeEntry = ActiveEntry.second;
                                  _carouselController.animateToItem(
                                    getIndexOfEntry(
                                      _secondEntry!,
                                      ActiveEntry.second,
                                    ),
                                  );
                                });
                              },
                              child: PictureDisplay(
                                picture: _secondEntry!.pictures[_selectedType]!,
                                highlight: _activeEntry == ActiveEntry.second,
                                width: 200,
                                borderRadius: 64,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  SegmentedButton(
                    showSelectedIcon: false,
                    segments: ProgressEntryType.values
                        .map(
                          (ProgressEntryType type) => ButtonSegment(
                            value: type,
                            label: Text(type.name),
                            enabled: _firstEntry.pictures[type] != null,
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
              // TODO : make the selected item centered
              controller: _carouselController,
              itemExtent: 80,
              shrinkExtent: 16,
              itemSnapping: true,

              onTap: (index) {
                setState(() {
                  if (_activeEntry == ActiveEntry.first) {
                    _firstEntry = entries[index];
                  } else {
                    _secondEntry = entries[index];
                  }
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
                        (_activeEntry == ActiveEntry.first &&
                                    e == _firstEntry) ||
                                (_activeEntry == ActiveEntry.second &&
                                    e == _secondEntry)
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: hasPreviousEntry()
                  ? () => move(CarouselDirection.left)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton.filled(
              iconSize: 16,
              onPressed: toggleMode,
              icon: FaIcon(
                mode == GalleryMode.display
                    ? FontAwesomeIcons.square
                    : FontAwesomeIcons.bars,
              ),
            ),
            IconButton(
              onPressed: hasNextEntry()
                  ? () => move(CarouselDirection.right)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
