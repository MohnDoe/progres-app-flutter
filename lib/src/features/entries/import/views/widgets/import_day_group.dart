import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/entry_status_provider.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';

import 'import_card.dart';

class ImportDayGroup extends ConsumerStatefulWidget {
  const ImportDayGroup({
    super.key,
    required this.date,
    required this.importItems,
  });

  final DateTime date;
  final List<ImportItem> importItems;

  @override
  ConsumerState<ImportDayGroup> createState() => _ImportDayGroupState();
}

class _ImportDayGroupState extends ConsumerState<ImportDayGroup> {
  @override
  Widget build(BuildContext context) {
    // Get the validity for THIS specific group
    final bool isThisGroupValid = ref.watch(
      importControllerProvider.select(
        (value) => value.groupValidity[widget.date] ?? false,
      ),
      // The `widget.date` here MUST be normalized the same way as the keys in groupValidity map
      // The keys in `groupValidity` are already normalized by _recalculateAllValidity
      // So, if widget.date might have time, normalize it:
      // importControllerProvider.select((value) {
      //   final normalizedDate = DateTime(widget.date.year, widget.date.month, widget.date.day);
      //   return value.groupValidity[normalizedDate] ?? false;
      // })
    );

    final normalizedWidgetDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
    final entryAlreadyExists = ref.watch(
      doesEntryExistForDateProvider(normalizedWidgetDate),
    );

    void onDeleteImportDayGroup(DateTime date) {
      ref.read(importControllerProvider.notifier).removeDay(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DAY HEADER
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMMd().format(widget.date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.importItems.length}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/${ProgressEntryType.values.length} max',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      if (entryAlreadyExists) // Display message if entry exists
                        Text(
                          "An entry already exists for this date.",
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
              Spacer(),
              entryAlreadyExists
                  ? FilledButton(
                      onPressed: () => onDeleteImportDayGroup(widget.date),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.errorContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onErrorContainer,
                      ),
                      child: const Text("Remove"),
                    )
                  : TextButton(
                      onPressed: () => onDeleteImportDayGroup(widget.date),
                      child: const Text("Remove day"),
                    ),
              if (isThisGroupValid && !entryAlreadyExists) Icon(Icons.check),
            ],
          ),
        ),
        // PICTURES
        SizedBox(
          width: double.infinity,
          height: entryAlreadyExists ? 100 : 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: widget.importItems
                .map(
                  (ImportItem importItem) => Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: ImportCard(
                      key: ValueKey(importItem),
                      importItem,
                      disabled: entryAlreadyExists,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
