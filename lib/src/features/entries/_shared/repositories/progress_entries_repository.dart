import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart'
    show PicturesFileService;

class ProgressEntriesRepository {
  List<ProgressEntry> entries = [];

  final _entriesController = StreamController<List<ProgressEntry>>.broadcast();
  Stream<List<ProgressEntry>> get entriesStream => _entriesController.stream;

  List<ProgressEntry> get orderedEntries {
    final orderedList = List<ProgressEntry>.from(
      entries,
    ); // Create a new list to avoid modifying the original

    orderedList.sort(
      (ProgressEntry a, ProgressEntry b) => b.date.compareTo(a.date),
    );

    return orderedList;
  }

  Future<void> addEntry(ProgressEntry entry) async {
    print('Adding entry');
    final Map<ProgressEntryType, ProgressPicture> pictures = {};
    for (ProgressEntryType entryType in entry.pictures.keys) {
      final File savedFile = await PicturesFileService().savePicture(
        entry,
        entryType,
        entry.pictures[entryType]!,
      );

      pictures[entryType] = ProgressPicture(file: savedFile);
    }

    final newEntry = ProgressEntry(pictures: pictures, date: entry.date);
    entries.add(newEntry);
    _entriesController.add(orderedEntries);
  }

  /*
  * Essentially editing an entry.
  * Deleting is ensures that files are "moved"
  * */
  Future<void> editEntry(ProgressEntry oldEntry, ProgressEntry newEntry) async {
    final Map<ProgressEntryType, ProgressPicture> finalEntryPictures = {};

    for (ProgressEntryType entryType in newEntry.pictures.keys) {
      finalEntryPictures[entryType] = await PicturesFileService()
          .duplicateProgressPicture(newEntry.pictures[entryType]!);
    }

    final finalEntry = ProgressEntry(
      pictures: finalEntryPictures,
      date: newEntry.date,
    );

    entries.removeWhere((e) => e.date == oldEntry.date);
    await addEntry(finalEntry);

    if (!newEntry.date.isAtSameMomentAs(oldEntry.date)) {
      await deleteEntry(oldEntry);
    }
  }

  Future<void> initEntries() async {
    entries = [];
    final List<Directory> matchingDirectories = await PicturesFileService()
        .listEntriesDirectory();

    for (Directory directory in matchingDirectories) {
      final entryTimestamp = directory.path.split(
        '/',
      )[directory.path.split('/').length - 1];

      final entryDate = DateTime.fromMicrosecondsSinceEpoch(
        int.parse(entryTimestamp) * 1000,
      );

      final newEntry = ProgressEntry(
        pictures: await PicturesFileService().getAllEntryTypesFromDate(
          entryDate,
        ),
        date: entryDate,
      );

      entries.add(newEntry);
    }
    _entriesController.add(orderedEntries);
  }

  Future<void> deleteEntry(ProgressEntry entry) async {
    print('Deleting entry');
    entries = entries
        .where((ProgressEntry e) => !e.date.isAtSameMomentAs(entry.date))
        .toList();

    _entriesController.add(orderedEntries);

    await PicturesFileService().deleteEntry(entry);
  }
}

final progressEntriesRepositoryProvider = Provider<ProgressEntriesRepository>(
  (ref) => ProgressEntriesRepository(),
);
