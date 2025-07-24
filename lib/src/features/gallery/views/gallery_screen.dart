import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/font_awesome_flutter/lib/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/gallery/widget/picture_display.dart';
import 'package:timeago/timeago.dart' as timeago;

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
  static const String name = 'gallery';
  static final String path = '/gallery/:entryType/:mode';

  final ProgressEntryType entryType;
  final ProgressEntry currentEntry;
  final ProgressEntry? secondEntry;

  final GalleryMode mode;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  final CarouselController _carouselController = CarouselController(initialItem: 0);
  ActiveEntry _activeEntry = ActiveEntry.first;

  late ProgressEntry _firstEntry;
  late ProgressEntry? _secondEntry;

  late ProgressEntryType _selectedType;

  late GalleryMode mode;

  void _initCarousel() {
    List<ProgressEntry> entries = ref
        .watch(progressEntriesRepositoryProvider)
        .orderedEntries
        .where((ProgressEntry entry) => entry.pictures[_selectedType] != null)
        .toList();

    // Find the index of the initial _firstEntry
    int initialIndex = entries.indexWhere(
      (entry) => entry.date.isAtSameMomentAs(_firstEntry.date),
    ); // Use a unique ID for comparison
    if (initialIndex == -1 && entries.isNotEmpty) {
      // Fallback if _firstEntry (for some reason) isn't in the initial list,
      // though it should be if widget.currentEntry has the widget.entryType picture.
      initialIndex = 0;
    } else if (entries.isEmpty) {
      initialIndex = 0; // Or handle empty list case appropriately
    }

    // Now initialize the CarouselController with the correct initialItem
    _carouselController.animateToItem(initialIndex);
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _firstEntry = widget.currentEntry;
    _secondEntry = widget.secondEntry;
    _selectedType = widget.entryType;
    mode = widget.mode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initCarousel();
    });
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

    void move(CarouselDirection direction, {bool far = false}) {
      final currentIndex = getIndexOfEntry(_firstEntry, _activeEntry);

      int newIndex = currentIndex;

      if (direction == CarouselDirection.right) {
        if (far) {
          newIndex = 0;
        } else {
          newIndex = max(currentIndex - 1, 0);
        }
      } else {
        if (far) {
          newIndex = entries.length - 1;
        } else {
          newIndex = min(currentIndex + 1, entries.length - 1);
        }
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

    bool isFirst() {
      final index = entries.indexOf(
        _activeEntry == ActiveEntry.first ? _firstEntry : _secondEntry!,
      );

      return index == entries.length - 1;
    }

    bool isLast() {
      final index = entries.indexOf(
        _activeEntry == ActiveEntry.first ? _firstEntry : _secondEntry!,
      );

      return index == 0;
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
      appBar: AppBar(
        title: Material(
          color: Colors.transparent,
          child: Row(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: ProgressEntryType.values
                .map(
                  (ProgressEntryType type) => ChoiceChip(
                    visualDensity: VisualDensity(
                      horizontal: VisualDensity.minimumDensity,
                      vertical: VisualDensity.minimumDensity,
                    ),
                    avatar: ProgressEntry.getIconFromType(type),
                    iconTheme: IconThemeData(size: 16),
                    label: Text(type.label),
                    showCheckmark: false,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    disabledColor: Theme.of(context).colorScheme.surfaceContainerLow,
                    selected: _selectedType == type,
                    onSelected:
                        // check if user can switch to side by side mode
                        // if not both pictures available then it's disabled (in side by side view)
                        (mode == GalleryMode.display &&
                                _firstEntry.pictures[type] != null) ||
                            (mode == GalleryMode.sideBySide &&
                                _firstEntry.pictures[type] != null &&
                                _secondEntry!.pictures[type] != null)
                        ? (bool _) {
                            setState(() {
                              _selectedType = type;
                            });
                          }
                        : null,
                  ),
                )
                .toList(),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
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
                        Text(
                          timeago.format(_firstEntry.date),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 16),
                        PictureDisplay(
                          picture: _firstEntry.pictures[_selectedType],
                          highlight: true,
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
                            Text(
                              timeago.format(_firstEntry.date),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _activeEntry = ActiveEntry.first;
                                  _carouselController.animateToItem(
                                    getIndexOfEntry(_firstEntry, ActiveEntry.first),
                                  );
                                });
                              },
                              child: PictureDisplay(
                                picture: _firstEntry.pictures[_selectedType],
                                highlight: _activeEntry == ActiveEntry.first,
                                width: 200,
                                borderRadius: 64,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Divider(),
                        ),
                        Column(
                          children: [
                            Text(
                              DateFormat.yMMMd().format(_secondEntry!.date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              timeago.format(_secondEntry!.date),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _activeEntry = ActiveEntry.second;
                                  _carouselController.animateToItem(
                                    getIndexOfEntry(_secondEntry!, ActiveEntry.second),
                                  );
                                });
                              },
                              child: PictureDisplay(
                                picture: _secondEntry!.pictures[_selectedType],
                                highlight: _activeEntry == ActiveEntry.second,
                                width: 200,
                                borderRadius: 64,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                        (_activeEntry == ActiveEntry.first && e == _firstEntry) ||
                                (_activeEntry == ActiveEntry.second && e == _secondEntry)
                            ? Container(
                                decoration: ShapeDecoration(
                                  shape: ContinuousRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(16)),
                                    side: BorderSide(
                                      width: 4,
                                      color: Theme.of(context).colorScheme.primary,
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
              onPressed: !isFirst()
                  ? () => move(CarouselDirection.left, far: true)
                  : null,
              iconSize: 16,
              icon: const FaIcon(FontAwesomeIcons.solidAnglesLeft),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: hasPreviousEntry() ? () => move(CarouselDirection.left) : null,
              iconSize: 16,
              icon: const FaIcon(FontAwesomeIcons.solidChevronLeft),
            ),
            IconButton.filled(
              iconSize: 16,
              onPressed: toggleMode,
              icon: FaIcon(
                mode == GalleryMode.display
                    ? FontAwesomeIcons.square
                    : FontAwesomeIcons.rectangleWide,
              ),
            ),
            IconButton(
              onPressed: hasNextEntry() ? () => move(CarouselDirection.right) : null,
              iconSize: 16,
              icon: const FaIcon(FontAwesomeIcons.solidChevronRight),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: !isLast()
                  ? () => move(CarouselDirection.right, far: true)
                  : null,
              iconSize: 16,
              icon: const FaIcon(FontAwesomeIcons.solidAnglesRight),
            ),
          ],
        ),
      ),
    );
  }
}
