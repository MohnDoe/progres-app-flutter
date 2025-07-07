import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/providers/entries_provider.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/entry_type_selection.dart';

class NewEntryBottomSheet extends ConsumerStatefulWidget {
  const NewEntryBottomSheet({super.key});

  @override
  ConsumerState<NewEntryBottomSheet> createState() =>
      _NewEntryBottomSheetState();
}

class _NewEntryBottomSheetState extends ConsumerState<NewEntryBottomSheet> {
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
                    .map((entryType) => EntryTypeSelection(type: entryType))
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
