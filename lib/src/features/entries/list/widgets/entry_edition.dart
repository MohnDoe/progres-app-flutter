import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/entry_status_provider.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entry_provider.dart';
import 'package:progres/src/features/entries/list/widgets/bottom_sheet/date_select_bottom_sheet.dart';

import 'bottom_sheet/widgets/entry_type_picture_card.dart';

class EntryEdition extends ConsumerStatefulWidget {
  const EntryEdition(this.initialEntry, {super.key});

  final ProgressEntry? initialEntry;

  @override
  ConsumerState createState() => _EntryEditionState();
}

class _EntryEditionState extends ConsumerState<EntryEdition> {
  @override
  void initState() {
    super.initState();
    // Initialize the notifier's state when the widget is first created
    // We use addPostFrameCallback to ensure that the ref is available and
    // we are not trying to update state during a build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialEntry != null) {
        // Call the method on your notifier to set the initial state
        ref
            .read(progressEntryStateNotifierProvider.notifier)
            .setEntry(widget.initialEntry!);
      } else {
        // Optionally, reset to a default state if initialEntry is null
        // This might already be handled by your notifier's constructor or reset method
        ref.read(progressEntryStateNotifierProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ProgressEntry entry = ref.watch(progressEntryStateNotifierProvider);

    final bool entryAlreadyExists = ref.watch(
      doesEntryExistForDateProvider(entry.date),
    );

    void resetEntry() {
      ref.read(progressEntryStateNotifierProvider.notifier).reset();
    }

    void deleteEntry() {
      ref.read(progressEntriesRepositoryProvider).deleteEntry(entry);
      // TODO: move this into onDeleteEntry
      if (context.mounted) Navigator.of(context).pop();
    }

    void saveEntry() async {
      await ref
          .read(progressEntriesRepositoryProvider)
          .editEntry(widget.initialEntry!, entry);
      resetEntry();
      // TODO: move this into onSaveEntry
      if (context.mounted) Navigator.of(context).pop();
    }

    void addNewEntry() async {
      await ref.read(progressEntriesRepositoryProvider).addEntry(entry);
      resetEntry();
      if (context.mounted) Navigator.of(context).pop();
    }

    bool canSaveEntry() {
      for (ProgressEntryType entryType in ProgressEntryType.values) {
        if (entry.pictures[entryType] != null) {
          return true;
        }
      }
      return false;
    }

    void displayDateSelectBottomSheet(
      BuildContext context,
      DateTime initialDate,
    ) async {
      final DateTime? selectedDate = await showModalBottomSheet<DateTime>(
        context: context,
        builder: (_) => DateSelectBottomSheet(initialDate: initialDate),
      );

      if (selectedDate == null) return;
      ref
          .read(progressEntryStateNotifierProvider.notifier)
          .setDate(selectedDate);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 20, left: 16, right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              if (widget.initialEntry != null)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      IconButton(
                        onPressed: deleteEntry,
                        icon: Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    widget.initialEntry != null
                        ? EntryDateText(entry.date)
                        : TextButton.icon(
                            onPressed: () {
                              displayDateSelectBottomSheet(context, entry.date);
                            },
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            iconAlignment: IconAlignment.end,
                            label: EntryDateText(entry.date),
                          ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 0),
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
                  onPressed: canSaveEntry()
                      ? widget.initialEntry == null
                            ? addNewEntry
                            : saveEntry
                      : null,
                  child: Text("Save"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EntryDateText extends StatelessWidget {
  const EntryDateText(this.date, {super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat.yMMMd().format(date),
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
