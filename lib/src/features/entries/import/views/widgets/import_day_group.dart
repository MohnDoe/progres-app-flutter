import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
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
    void onDeleteImportDayGroup(DateTime date) {
      ref.read(importControllerProvider.notifier).removeDay(date);
    }

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
                      child: ImportCard(importItem),
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
