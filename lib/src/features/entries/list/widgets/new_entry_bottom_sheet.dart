import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/providers/entries_provider.dart';
import 'package:progres/src/features/entries/list/widgets/picture_source_selection_bottom_sheet.dart';

class NewEntryBottomSheet extends ConsumerStatefulWidget {
  const NewEntryBottomSheet({super.key});

  void onSelectSide(
    BuildContext context,
    ProgressEntryType entryType,
    void Function(ProgressEntryType entryType, ProgressPicture picture)
    onSelection,
  ) {
    _displayPictureSourceOptions(context, entryType, onSelection);
  }

  void _displayPictureSourceOptions(
    BuildContext context,
    ProgressEntryType entryType,
    void Function(ProgressEntryType entryType, ProgressPicture picture)
    onSelection,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return PictureSourceSelectionBottomSheet(
          onSelectionDone: (ProgressPicture picture) =>
              onSelection(entryType, picture),
        );
      },
    );
  }

  @override
  ConsumerState<NewEntryBottomSheet> createState() =>
      _NewEntryBottomSheetState();
}

class _NewEntryBottomSheetState extends ConsumerState<NewEntryBottomSheet> {
  void _onProgressPictureSelectionDone(
    ProgressEntryType type,
    ProgressPicture picture,
  ) {
    print('hello');
    ref
        .read(progressEntryProvider.notifier)
        .setProgressPictureToType(type, picture);
  }

  @override
  Widget build(BuildContext context) {
    ProgressEntry entry = ref.watch(progressEntryProvider);

    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        "Progress photos",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        DateFormat.yMMMd().format(entry.date),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ProgressEntryType.values
                    .map(
                      (entryType) => Column(
                        children: [
                          Text(
                            entryType.name,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          SizedBox(height: 4),
                          InkWell(
                            onTap: () => widget.onSelectSide(
                              context,
                              entryType,
                              _onProgressPictureSelectionDone,
                            ),
                            child: Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                                  width: 2,
                                ),
                              ),
                              child: entry.pictures[entryType] != null
                                  ? Image(
                                      image: FileImage(
                                        entry.pictures[entryType]!.file,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : Text('R'),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: () {}, child: Text("Save")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
