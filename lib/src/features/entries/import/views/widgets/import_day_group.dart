import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/entry_status_provider.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';

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
    void onDeleteImportDayGroup(DateTime date) {
      ref.read(importControllerProvider.notifier).removeDay(date);
    }

    final bool entryAlreadyExists = ref.watch(
      doesEntryExistForDateProvider(widget.date),
    );

    // --- Start of isValid logic ---
    bool isValid = false; // Default to false
    // Condition 1: No more than 3 import items
    if (widget.importItems.length <= ProgressEntryType.values.length) {
      // Or a hardcoded 3 if that's the absolute max
      // Condition 2: Each importItem has a type set to a different value, and none are null.
      if (widget.importItems.isNotEmpty) {
        // Only proceed if there are items to check
        final Set<ProgressEntryType> uniqueTypes = {};
        bool allTypesValidAndUnique = true;

        for (final item in widget.importItems) {
          if (item.type == null) {
            allTypesValidAndUnique = false;
            break; // Found a null type, no need to check further
          }
          if (uniqueTypes.contains(item.type!)) {
            allTypesValidAndUnique = false;
            break; // Found a duplicate type
          }
          uniqueTypes.add(item.type!);
        }
        isValid = allTypesValidAndUnique;
      } else {
        // If importItems is empty, it can be considered valid based on the conditions
        // (no more than 3 items, and the condition about types is vacuously true).
        // Adjust this if empty should be invalid.
        isValid = true;
      }
    }
    // --- End of isValid logic ---

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Text(
                  DateFormat.yMMMMd().format(widget.date),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (entryAlreadyExists) // Display message if entry exists
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      "An entry already exists for this date.",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.orange.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Spacer(),
                Row(
                  children: [
                    Text(
                      '${widget.importItems.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '/${ProgressEntryType.values.length}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => onDeleteImportDayGroup(widget.date),
                  icon: Icon(Icons.delete_outline, size: 16),
                ),
                if (isValid) Icon(Icons.check),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: widget.importItems
                  .map(
                    (ImportItem importItem) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: ImportCard(key: ValueKey(importItem), importItem),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
