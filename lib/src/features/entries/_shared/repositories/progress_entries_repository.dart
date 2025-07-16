import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart'
    show PicturesFileService;

class ProgressEntriesRepository {
  List<ProgressEntry> entries = [];

  final _entriesController = StreamController<List<ProgressEntry>>.broadcast();
  Stream<List<ProgressEntry>> get entriesStream => _entriesController.stream;

  List<ProgressEntry> get orderedEntries {
    final sortedList = List<ProgressEntry>.from(
      entries,
    ); // Create a new list to avoid modifying the original

    sortedList.sort(
      (ProgressEntry a, ProgressEntry b) => b.date.compareTo(a.date),
    );

    return List.unmodifiable(sortedList);
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

    final newEntry = ProgressEntry(
      pictures: pictures,
      date: entry.date,
      lastModifiedTimestamp: DateTime.now().microsecondsSinceEpoch,
    );

    final newEntries = List<ProgressEntry>.from(entries);
    newEntries.add(newEntry);

    entries = newEntries;

    _entriesController.add(orderedEntries);
  }

  Future<void> editEntry(ProgressEntry oldEntry, ProgressEntry newEntry) async {
    // Ensure date is not changing, as this logic assumes it.
    assert(
      oldEntry.date.isAtSameMomentAs(newEntry.date),
      "Date mismatch in editEntry",
    );
    print('Editing entry for date: ${oldEntry.date}');

    final pictureService = PicturesFileService();
    final tempDir = await getTemporaryDirectory();
    final List<File> tempFilesCreated = []; // To manage cleanup
    final Map<ProgressEntryType, ProgressPicture> finalPicturesInEntry = {};

    try {
      // --- Pass 1: Preparation and Planning ---
      // For each type in newEntry, what is its intended source file?
      final Map<ProgressEntryType, File> intendedSourceFilesForNewEntry = {};
      // Pictures from oldEntry that might be deleted if not reused or moved.
      final Set<ProgressEntryType> typesWithPicturesInOldEntry = oldEntry
          .pictures
          .keys
          .toSet();

      for (ProgressEntryType currentType in ProgressEntryType.values) {
        final ProgressPicture? newPicData = newEntry.pictures[currentType];
        final ProgressPicture? oldPicData = oldEntry.pictures[currentType];

        if (newPicData != null) {
          // There's a picture for this type in newEntry.
          if (oldPicData != null &&
              newPicData.file.path == oldPicData.file.path) {
            // Case 1: Picture is unchanged. Mark for direct reuse.
            print("Reusing picture for $currentType: ${newPicData.file.path}");
            finalPicturesInEntry[currentType] = newPicData;
            // This picture from oldEntry is accounted for.
            typesWithPicturesInOldEntry.remove(currentType);
            continue; // Next type
          }

          // Case 2: Picture is new or changed (path is different from old, or old was null).
          // The source for this is newPicData.file.
          File sourceForThisType = newPicData.file;

          print(
            "Saving new picture for $currentType from source: ${sourceForThisType.path}",
          );

          if (!await sourceForThisType.exists()) {
            print(
              "ERROR: Source file ${sourceForThisType.path} for $currentType (from newEntry) does not exist. Skipping this type.",
            );
            continue;
          }

          // Critical Check for Swaps/Moves:
          // Is this sourceFile (`sourceForThisType`) also a canonical file of *another* type in oldEntry
          // which is *also* being modified or removed in this operation?
          // If so, we need to copy `sourceForThisType` to a temp location before it's potentially overwritten
          // or deleted when its original type is processed.
          bool needsTempCopy = false;
          for (ProgressEntryType oldType in oldEntry.pictures.keys) {
            if (oldEntry.pictures[oldType]?.file.path ==
                sourceForThisType.path) {
              // `sourceForThisType` (e.g., new 'front' wants old 'side's file) IS an existing canonical file.
              // Will this `oldType`'s canonical file be overwritten or deleted?
              // It will be overwritten if `newEntry.pictures[oldType]` is different or null.
              final newPicForOldType = newEntry.pictures[oldType];
              if (newPicForOldType == null ||
                  newPicForOldType.file.path != sourceForThisType.path) {
                // Yes, oldType (which `sourceForThisType` belongs to) is changing.
                needsTempCopy = true;
                break;
              }
            }
          }

          if (needsTempCopy) {
            print(
              "Preparing temp copy for $currentType from source ${sourceForThisType.path} (which is a canonical file being modified).",
            );
            final tempFile = File(
              p.join(
                tempDir.path,
                '${DateTime.now().microsecondsSinceEpoch}_${p.basename(sourceForThisType.path)}',
              ),
            );
            await sourceForThisType.copy(tempFile.path);
            tempFilesCreated.add(tempFile);
            intendedSourceFilesForNewEntry[currentType] =
                tempFile; // Use temp file as source
          } else {
            intendedSourceFilesForNewEntry[currentType] =
                sourceForThisType; // Use original source
          }
          // This picture from oldEntry (if oldPicData was not null) is being replaced.
          typesWithPicturesInOldEntry.remove(currentType);
        } else {
          // newPicData is null for currentType
          if (oldPicData != null) {
            // Picture for currentType is being removed, it's already in typesWithPicturesInOldEntry
            // and will be handled by deletion if not moved.
            print(
              "Picture for $currentType marked for potential deletion (was in old, not in new).",
            );
          }
        }
      }

      // --- Pass 2: Save to Canonical Locations ---
      for (ProgressEntryType typeToSave
          in intendedSourceFilesForNewEntry.keys) {
        final File sourceFile = intendedSourceFilesForNewEntry[typeToSave]!;
        print("Saving picture for $typeToSave from source: ${sourceFile.path}");
        try {
          final File savedCanonicalFile = await pictureService.savePicture(
            oldEntry, // Contains the correct date for directory structure
            typeToSave,
            ProgressPicture(file: sourceFile),
          );
          finalPicturesInEntry[typeToSave] = ProgressPicture(
            file: savedCanonicalFile,
          );
        } catch (e) {
          print("ERROR saving $typeToSave from ${sourceFile.path}: $e");
          // Decide: attempt to reuse old picture if one existed?
          if (oldEntry.pictures[typeToSave] != null) {
            print(
              "Attempting to fallback to old picture for $typeToSave due to save error.",
            );
            finalPicturesInEntry[typeToSave] = oldEntry.pictures[typeToSave]!;
          }
        }
      }

      // --- Pass 3: Cleanup ---
      // Delete old pictures that are no longer used AT ALL by the new entry.
      // typesWithPicturesInOldEntry now contains types that had pictures in oldEntry
      // but are NOT represented in finalPicturesInEntry (either by reuse or by saving a new one).
      for (ProgressEntryType typeToDeleteFromOld
          in typesWithPicturesInOldEntry) {
        // Double check it wasn't actually moved (i.e., its file isn't now used by another type in finalPicturesInEntry)
        // This check is a bit redundant due to the temp copy logic but is a safeguard.
        bool fileWasMoved = false;
        if (oldEntry.pictures[typeToDeleteFromOld] != null) {
          String oldFilePath =
              oldEntry.pictures[typeToDeleteFromOld]!.file.path;
          for (var finalPic in finalPicturesInEntry.values) {
            if (finalPic.file.path == oldFilePath) {
              fileWasMoved = true;
              break;
            }
          }
        }

        if (!fileWasMoved) {
          print("Deleting old, unused picture for type $typeToDeleteFromOld.");
          try {
            await pictureService.deletePicture(oldEntry, typeToDeleteFromOld);
          } catch (e) {
            print("ERROR deleting old picture for $typeToDeleteFromOld: $e");
          }
        } else {
          print(
            "Old picture for $typeToDeleteFromOld was moved, not deleting its original canonical file directly here (handled by overwrite or type removal).",
          );
        }
      }
    } finally {
      // Ensure temp files are always cleaned up
      for (File tempFile in tempFilesCreated) {
        if (await tempFile.exists()) {
          print("Deleting temp file: ${tempFile.path}");
          await tempFile.delete();
        }
      }
    }

    // --- Step 4: Update In-Memory State ---
    final ProgressEntry fullyUpdatedEntry = ProgressEntry(
      pictures: finalPicturesInEntry,
      date: oldEntry.date,
      lastModifiedTimestamp: DateTime.now().microsecondsSinceEpoch,
    );

    entries = [
      for (final entry in entries)
        if (entry.date.isAtSameMomentAs(fullyUpdatedEntry.date))
          fullyUpdatedEntry
        else
          entry,
    ];
    _entriesController.add(List.unmodifiable(entries));

    print("Entry edit complete for date: ${oldEntry.date}");
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
        lastModifiedTimestamp: DateTime.now().microsecondsSinceEpoch,
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
