import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/picker/picker.dart';
import 'package:progres/src/features/entries/import/controllers/import_controller.dart';
import 'package:progres/src/features/entries/import/views/widgets/import_day_group.dart';
import 'package:progres/src/features/entries/import/views/widgets/import_card.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  @override
  void initState() {
    super.initState();
    importPictures();
  }

  void importPictures() async {
    final List<ProgressPicture> selectedPictures = await Picker().pickImages();
    for (ProgressPicture picture in selectedPictures) {
      ref.read(importControllerProvider.notifier).addProgressPicture(picture);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the STATE of the provider (the List<ProgressEntry>)
    final List<ImportItem> importItems = ref.watch(importControllerProvider);

    importItems.sort(
      (ImportItem a, ImportItem b) => -(a.date).compareTo((b.date)),
    );
    // 2. Compute groupedByDay based on the current state (entries)
    final Map<DateTime, List<ImportItem>> groupedByDay = {};
    for (final item in importItems) {
      final date = item.date;
      if (!groupedByDay.containsKey(date)) {
        groupedByDay[date] = [];
      }
      groupedByDay[date]!.add(item);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Importing ${importItems.length} photos')),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListView.builder(
          itemCount: groupedByDay.length,
          itemBuilder: (context, index) => ImportDayGroup(
            date: groupedByDay.keys.elementAt(index),
            importItems: groupedByDay.values.elementAt(index),
          ),
        ),
      ),
    );
  }
}
