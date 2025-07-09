import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/picker/picker.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';
import 'package:progres/src/features/entries/import/views/widgets/import_day_group.dart';
import 'package:progres/src/features/entries/import/views/widgets/import_card.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  @override
  void initState() {
    super.initState();
    addPicturesPickerStart();
  }

  void addPicturesPickerStart() async {
    final List<ProgressPicture> selectedPictures = await Picker().pickImages();
    for (ProgressPicture picture in selectedPictures) {
      ref.read(importControllerProvider.notifier).addProgressPicture(picture);
    }
  }

  void importPictures() async {
    await ref.read(importControllerProvider.notifier).saveImports();
    ref.read(importControllerProvider.notifier).resetImport();
    ref.read(listEntriesControllerProvider.notifier).loadEntries();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the STATE of the provider (the List<ProgressEntry>)
    final List<ImportItem> importItems = ref.watch(importControllerProvider);
    final groupedByDay = ref
        .watch(importControllerProvider.notifier)
        .groupedByDay;
    // 1.b Sort by date descending

    return Scaffold(
      appBar: AppBar(title: Text('Importing ${importItems.length} photos')),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.builder(
          itemCount: groupedByDay.length,
          itemBuilder: (context, index) {
            final DateTime date = groupedByDay.keys.elementAt(index);
            final List<ImportItem> importItemsForDay = groupedByDay[date]!;
            return ImportDayGroup(
              key: ValueKey(date),
              date: date,
              importItems: importItemsForDay,
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: Icon(Icons.add),
              onPressed: addPicturesPickerStart,
              label: Text("Add more photos"),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: importPictures, child: Text('Import')),
          ],
        ),
      ),
    );
  }
}
