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

  void resetImport() async {
    state = [];
  }

  List<ProgressEntry> groupImportIntoProgressEntries() {
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
    final Map<DateTime, List<ImportItem>> result = {};
    for (final item in orderedByDate) {
      final date = item.date;
      if (!result.containsKey(date)) {
        result[date] = [];
      }
      result[date]!.add(item);
    }
    return result;
  }

  Future<void> saveImports() async {
    for (ProgressEntry progressEntry in groupImportIntoProgressEntries()) {
      await ProgressEntriesRepository().addEntry(progressEntry);
    }
  }

  Future<void> addProgressPicture(ProgressPicture picture) async {
    if (state.any((item) => item.picture.file.path == picture.file.path)) {
      return;
    }

    final exifFile = await Exif.fromPath(picture.file.path);
    final pictureOriginalDate = await exifFile.getOriginalDate();

    final importItem = ImportItem(
      picture: picture,
      type: null,
      date: PicturesFileService().toFixedDate(
        pictureOriginalDate ?? DateTime.now(),
      ),
    );

    state = [...state, importItem];
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

  void removeDay(DateTime date) {
    state = state
        .where((ImportItem entry) => !entry.date.isAtSameMomentAs(date))
        .toList();
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
}

final importControllerProvider =
    StateNotifierProvider<ImportControllerNotifier, List<ImportItem>>((ref) {
      return ImportControllerNotifier();
    });
