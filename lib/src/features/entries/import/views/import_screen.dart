import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/picker/picker.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';
import 'package:progres/src/features/entries/import/views/widgets/import_day_group.dart';

class ImportScreen extends ConsumerStatefulWidget {
  static const String name = 'import';
  static const String path = '/import';

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
    ref.read(importControllerProvider.notifier).clearImport();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importControllerProvider); // DO NOT DELETE

    final bool isEntireImportValid = importState.isEntireImportValid;
    final importNotifier = ref.watch(importControllerProvider.notifier);
    final groupedData = importNotifier.groupedItemsForDisplay;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.separated(
          itemCount: groupedData.length,
          itemBuilder: (context, index) {
            final DateTime date = groupedData.keys.elementAt(index);
            final List<ImportItem> importItemsForDay = groupedData[date]!;
            return ImportDayGroup(
              key: ValueKey(date),
              date: date,
              importItems: importItemsForDay,
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 16),
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
            // TODO: enforce rules for import validation
            FilledButton(
              onPressed: isEntireImportValid ? importPictures : null,
              child: Text('Import'),
            ),
          ],
        ),
      ),
    );
  }
}
