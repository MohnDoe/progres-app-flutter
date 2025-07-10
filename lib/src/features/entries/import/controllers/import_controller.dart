import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:native_exif/native_exif.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart';

import '../../_shared/repositories/progress_entries_repository.dart';

class ImportItem {
  ImportItem({required this.picture, this.type, required this.date});
  final ProgressPicture picture;
  final ProgressEntryType? type;
  final DateTime date;
}

class ImportControllerNotifier extends StateNotifier<List<ImportItem>> {
  ImportControllerNotifier() : super([]);

  void resetImports() async {
    state = [];
  }

  List<ProgressEntry> convertImportDaysToProgressEntriesList() {
    final List<ProgressEntry> progressEntries = [];

    for (DateTime day in groupedByDay.keys) {
      final List<ImportItem> importItems = groupedByDay[day]!;
      final Map<ProgressEntryType, ProgressPicture> pictures = {};
      for (ImportItem item in importItems) {
        pictures[item.type!] = item.picture;
      }
      final progressEntry = ProgressEntry(pictures: pictures, date: day);
      progressEntries.add(progressEntry);
    }

    return progressEntries;
  }

  List<ImportItem> get orderedByDate {
    final orderedList = List<ImportItem>.from(
      state,
    ); // Create a new list to avoid modifying the original
    orderedList.sort(
      (ImportItem a, ImportItem b) => -(a.date).compareTo((b.date)),
    );

    return orderedList;
  }

  Map<DateTime, List<ImportItem>> get groupedByDay {
    print(
      "ImportControllerNotifier: groupedByDay GETTER CALLED. Current state count: ${state.length}",
    ); // DEBUG
    final Map<DateTime, List<ImportItem>> groups = {};
    for (final item in state) {
      // ALWAYS uses the current `state`
      final dateKey = DateTime(
        item.date.year,
        item.date.month,
        item.date.day,
      ); // Normalize for grouping
      groups.update(
        dateKey,
        (existingItems) => [...existingItems, item],
        ifAbsent: () => [item],
      );
    }
    // Optional: Sort groups by date if needed
    // final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a)); // Descending
    // final Map<DateTime, List<ImportItem>> sortedGroups = {
    //   for (var key in sortedKeys) key: groups[key]!
    // };
    // return sortedGroups;
    return groups;
  }

  Future<void> saveImports() async {
    for (ProgressEntry progressEntry
        in convertImportDaysToProgressEntriesList()) {
      await ProgressEntriesRepository().addEntry(progressEntry);
    }
  }

  Future<void> addProgressPicture(ProgressPicture picture) async {
    if (state.any((item) => item.picture.file.path == picture.file.path)) {
      print(
        "addProgressPicture: Picture ${picture.file.path} already exists in state. Skipping.",
      );
      return;
    }

    // 2. Get EXIF data
    Exif? exifFile; // Use nullable Exif
    DateTime? pictureOriginalDate;
    try {
      exifFile = await Exif.fromPath(picture.file.path);
      pictureOriginalDate = await exifFile.getOriginalDate();
      print(
        "addProgressPicture: EXIF original date: $pictureOriginalDate for ${picture.file.path}",
      );
    } catch (e) {
      print(
        "addProgressPicture: Error reading EXIF for ${picture.file.path}: $e",
      );
      // For now, it will fall through to pictureOriginalDate being null, then use DateTime.now().
    }

    final importItem = ImportItem(
      picture: picture,
      type: null,
      date: PicturesFileService().toFixedDate(
        pictureOriginalDate ?? DateTime.now(),
      ),
    );
    print(
      "addProgressPicture: Created ImportItem for date: ${importItem.date}, path: ${importItem.picture.file.path}",
    );

    // 4. Update state IMMUTABLY
    state = [
      ...state,
      importItem,
    ]; // Creates a new list with the old items + new item
    print(
      "addProgressPicture: Picture added. New state count: ${state.length}",
    );
    if (state.isNotEmpty) {
      print(
        "addProgressPicture: Last item added date: ${state.last.date}, path: ${state.last.picture.file.path}",
      );
    }
  }

  void removeProgressPicture(ProgressPicture picture) async {
    state = state.where((item) => item.picture != picture).toList();
  }

  void clearImport() async {
    state = [];
  }

  void removePictureFromImports(ProgressPicture picture) async {
    state = state.where((item) => item.picture != picture).toList();
  }

  void removeDay(DateTime dateToRemove) {
    print(
      "ImportControllerNotifier: removeDay called for date: $dateToRemove",
    ); // For debugging

    state = state.where((entry) {
      // Normalize dates to ensure correct comparison (if time components might differ)
      final normalizedEntryDate = DateTime(
        entry.date.year,
        entry.date.month,
        entry.date.day,
      );
      final normalizedDateToRemove = DateTime(
        dateToRemove.year,
        dateToRemove.month,
        dateToRemove.day,
      );
      return !normalizedEntryDate.isAtSameMomentAs(normalizedDateToRemove);
    }).toList();

    print(
      "ImportControllerNotifier: State after removeDay. New count: ${state.length}",
    ); // For debugging
    // If state is empty now, print that too
    if (state.isEmpty) {
      print("ImportControllerNotifier: State is now empty.");
    } else {
      print(
        "ImportControllerNotifier: First entry date in new state (if any): ${state.first.date}",
      );
    }
  }

  void updatePictureEntryType(
    ProgressPicture picture,
    ProgressEntryType entryType,
  ) {
    final correspondingItem = state.firstWhere(
      (item) => item.picture == picture,
    );
    final correspondingItemIndex = state.indexOf(correspondingItem);
    final newImportItem = ImportItem(
      picture: correspondingItem.picture,
      date: correspondingItem.date,
      type: entryType,
    );

    final newState = List<ImportItem>.from(state);
    newState[correspondingItemIndex] = newImportItem;
    state = newState;
  }

  void init(List<ImportItem> initialImportItems) {
    state = initialImportItems;
  }
}

final importControllerProvider =
    StateNotifierProvider<ImportControllerNotifier, List<ImportItem>>((ref) {
      return ImportControllerNotifier();
    });
