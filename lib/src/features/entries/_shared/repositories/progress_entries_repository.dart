import 'dart:io';

import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart'
    show PicturesFileService;

class ProgressEntriesRepository {
  List<ProgressEntry> entries = [];

  List<ProgressEntry> get orderedEntries {
    final orderedList = List<ProgressEntry>.from(
      entries,
    ); // Create a new list to avoid modifying the original

    orderedList.sort(
      (ProgressEntry a, ProgressEntry b) => a.date.compareTo(b.date),
    );

    return orderedList;
  }

  Future<void> saveEntry(ProgressEntry entry) async {
    final Map<ProgressEntryType, ProgressPicture> pictures = {};
    for (ProgressEntryType entryType in entry.pictures.keys) {
      final File savedFile = await PicturesFileService().savePicture(
        entry,
        entryType,
        entry.pictures[entryType]!,
      );

      pictures[entryType] = ProgressPicture(file: savedFile);
    }

    entries.add(ProgressEntry(pictures: pictures, date: entry.date));
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
  }
}
