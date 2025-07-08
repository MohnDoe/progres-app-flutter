import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/providers/entries_provider.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/date_select_bottom_sheet.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/widgets/entry_type_picture_card.dart';

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

    void saveEntry() async {
      await ref.read(progressEntriesRepositoryProvider).saveEntry(entry);
      if (context.mounted) Navigator.of(context).pop();
    }

    void displayerDateSelectBottomSheet(
      BuildContext context,
      DateTime initialDate,
    ) async {
      final DateTime? selectedDate = await showModalBottomSheet<DateTime>(
        context: context,
        builder: (_) => DateSelectBottomSheet(initialDate: initialDate),
      );

      if (selectedDate == null) return;
      ref.read(progressEntryProvider.notifier).setDate(selectedDate);
    }

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
                      TextButton.icon(
                        onPressed: () {
                          displayerDateSelectBottomSheet(context, entry.date);
                        },
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),

                        iconAlignment: IconAlignment.end,
                        label: Text(
                          DateFormat.yMMMd().format(entry.date),
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                      Text(
                        "Progress photos",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.color!.withAlpha(200),
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
                    .map((entryType) => EntryTypePictureCard(type: entryType))
                    .toList(),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: saveEntry,
                    child: Text("Save"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
