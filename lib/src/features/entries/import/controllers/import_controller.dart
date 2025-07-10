import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:native_exif/native_exif.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart';
import 'package:progres/src/features/entries/_shared/repositories/entry_status_provider.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';

import '../../_shared/repositories/progress_entries_repository.dart';

class ImportItem {
  ImportItem({required this.picture, this.type, required this.date});
  final ProgressPicture picture;
  final ProgressEntryType? type;
  final DateTime date;
}

class ImportValidityState {
  final Map<DateTime, bool> groupValidity; // Validity of each individual group
  final bool
  isEntireImportValid; // Overall validity for the "Import All" button
  final List<ImportItem> items; // The actual import items

  ImportValidityState({
    required this.items,
    required this.groupValidity,
    required this.isEntireImportValid,
  });

  factory ImportValidityState.initial() {
    return ImportValidityState(
      items: [],
      groupValidity: {},
      isEntireImportValid: false,
    );
  }

  ImportValidityState copyWith({
    List<ImportItem>? items,
    Map<DateTime, bool>? groupValidity,
    bool? isEntireImportValid,
  }) {
    return ImportValidityState(
      items: items ?? this.items,
      groupValidity: groupValidity ?? this.groupValidity,
      isEntireImportValid: isEntireImportValid ?? this.isEntireImportValid,
    );
  }
}

class ImportControllerNotifier extends StateNotifier<ImportValidityState> {
  // To access existingEntryDates, the notifier needs a Ref
  final Ref _ref;

  ImportControllerNotifier(this._ref) : super(ImportValidityState.initial()) {
    _ref.listen(
      existingEntryDatesProvider,
      (_, __) => _recalculateAllValidity(),
    );
    // _recalculateAllValidity(); // Initial calculation
  }
  // Getter for ImportScreen to get grouped items
  Map<DateTime, List<ImportItem>> get groupedItemsForDisplay {
    return _getGroupedItems(state.items);
  }

  // Helper to group items by date (same as your current groupedByDay logic)
  Map<DateTime, List<ImportItem>> _getGroupedItems(
    List<ImportItem> currentItems,
  ) {
    final Map<DateTime, List<ImportItem>> groups = {};
    for (final item in currentItems) {
      final dateKey = DateTime(item.date.year, item.date.month, item.date.day);
      groups.update(
        dateKey,
        (existing) => [...existing, item],
        ifAbsent: () => [item],
      );
    }
    return groups;
  }

  void _recalculateAllValidity() {
    final Set<DateTime> existingDates = _ref.read(
      existingEntryDatesProvider,
    ); // Read current existing dates
    final grouped = _getGroupedItems(state.items);
    final Map<DateTime, bool> newGroupValidity = {};
    bool overallValidity = grouped
        .isNotEmpty; // Import is only valid if there's at least one group. Adjust if needed.

    if (grouped.isEmpty) {
      overallValidity = false; // Cannot import if there's nothing
    } else {
      for (final dateKey in grouped.keys) {
        final itemsForGroup = grouped[dateKey]!;
        final isValidGroup = isImportGroupValid(
          itemsForGroup,
          dateKey,
          existingDates,
        );
        newGroupValidity[dateKey] = isValidGroup;
        if (!isValidGroup) {
          overallValidity =
              false; // If any group is invalid, the whole import is invalid
        }
      }
    }
    state = state.copyWith(
      groupValidity: newGroupValidity,
      isEntireImportValid: overallValidity,
    );
    print(
      "ImportControllerNotifier: Recalculated validity. Overall: ${state.isEntireImportValid}. Groups: ${state.groupValidity}",
    );
  }

  List<ProgressEntry> groupImportIntoProgressEntries() {
    final List<ProgressEntry> progressEntries = [];

    final groupedByDay = _getGroupedItems(state.items);

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

  Future<void> saveImports() async {
    if (!state.isEntireImportValid) {
      print("ImportControllerNotifier: Attempted to save invalid import.");
      return; // Or throw an error / show a message
    }

    final progressEntriesToSave =
        groupImportIntoProgressEntries(); // Your existing logic

    if (progressEntriesToSave.isEmpty) {
      print("ImportControllerNotifier: No valid entries to save.");
      return;
    }
    try {
      final mainEntriesRepository = _ref.read(
        progressEntriesRepositoryProvider,
      ); // Get your main repo
      for (final entry in progressEntriesToSave) {
        await mainEntriesRepository.addEntry(entry); // Or a batch save method
      }
      print(
        "ImportControllerNotifier: Successfully saved ${progressEntriesToSave.length} entries to main repository.",
      );

      // --- REFRESH THE MAIN ENTRIES LIST ---
      _ref.refresh(listEntriesControllerProvider);
      print(
        "ImportControllerNotifier: listEntriesControllerProvider refreshed.",
      );

      // Clear the import state after successful import
      clearImport();
    } catch (e) {
      print("ImportControllerNotifier: Error saving imported entries: $e");
      // Handle error: show message to user, maybe don't clearImport()
    } finally {
      // Hide loading state on ImportScreen
    }
  }

  Future<void> addProgressPicture(ProgressPicture picture) async {
    if (state.items.any(
      (item) => item.picture.file.path == picture.file.path,
    )) {
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

    final newItems = [...state.items, importItem];
    state = state.copyWith(
      items: newItems,
    ); // Creates a new list with the old items + new item
    _recalculateAllValidity();
  }

  void removePictureFromImports(ProgressPicture picture) async {
    state = state.copyWith(
      items: state.items.where((item) => item.picture != picture).toList(),
    );
    _recalculateAllValidity();
  }

  void removeDay(DateTime dateToRemove) {
    print(
      "ImportControllerNotifier: removeDay called for date: $dateToRemove",
    ); // For debugging

    final newItems = state.items.where((entry) {
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

    state = state.copyWith(items: newItems);
    _recalculateAllValidity();
  }

  void updatePictureEntryType(
    ProgressPicture picture,
    ProgressEntryType entryType,
  ) {
    final correspondingItem = state.items.firstWhere(
      (item) => item.picture == picture,
    );
    final correspondingItemIndex = state.items.indexOf(correspondingItem);
    final newImportItem = ImportItem(
      picture: correspondingItem.picture,
      date: correspondingItem.date,
      type: entryType,
    );

    final newItems = List<ImportItem>.from(state.items);
    newItems[correspondingItemIndex] = newImportItem;
    state = state.copyWith(items: newItems);
    _recalculateAllValidity();
  }

  void init(List<ImportItem> initialImportItems) {
    state = ImportValidityState(
      items: initialImportItems,
      groupValidity: {},
      isEntireImportValid: false,
    );
  }

  void clearImport() {
    state =
        ImportValidityState.initial(); // Resets everything including validity
  }

  bool isImportGroupValid(
    List<ImportItem> importItems,
    DateTime groupDate,
    Set<DateTime> existingEntryDates,
  ) {
    // Condition 0: Check if an entry already exists for this date in the main data store
    final normalizedGroupDate = DateTime(
      groupDate.year,
      groupDate.month,
      groupDate.day,
    );
    if (existingEntryDates.contains(normalizedGroupDate)) {
      // print("isImportGroupValid for $groupDate: FALSE (entry already exists in main store)");
      return false; // Cannot import if an entry already exists for this date
    }

    // Condition 1: No more than ProgressEntryType.values.length items
    if (importItems.length > ProgressEntryType.values.length) {
      // print("isImportGroupValid for $groupDate: FALSE (too many items: ${importItems.length})");
      return false;
    }

    // Condition 2: Each importItem has a type set to a different value, and none are null.
    if (importItems.isNotEmpty) {
      final Set<ProgressEntryType> uniqueTypes = {};
      for (final item in importItems) {
        if (item.type == null) {
          // print("isImportGroupValid for $groupDate: FALSE (item type is null)");
          return false; // Found a null type
        }
        if (uniqueTypes.contains(item.type!)) {
          // print("isImportGroupValid for $groupDate: FALSE (duplicate type: ${item.type})");
          return false; // Found a duplicate type
        }
        uniqueTypes.add(item.type!);
      }
    }
    // If importItems is empty, it could be considered valid or invalid based on requirements.
    // For an import, an empty group might be valid if it's simply skipped, or invalid if every day must have items.
    // Let's assume an empty group (that doesn't already exist in main store) is valid for now for the purpose of individual group check.
    // The overall "is entire import valid" might have a stricter rule (e.g., no empty groups allowed for final save).

    // print("isImportGroupValid for $groupDate: TRUE");
    return true;
  }
}

final importControllerProvider =
    StateNotifierProvider<ImportControllerNotifier, ImportValidityState>((ref) {
      return ImportControllerNotifier(ref);
    });
