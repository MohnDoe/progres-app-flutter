import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';

const kProjectId = '1';

class PicturesFileService {
  Future<String> get _userPicturesPath async {
    final directory = await getApplicationDocumentsDirectory();

    return '${directory.path}/user_pictures';
  }

  Future<String> get _saveDirPath async {
    final userPicturesDir = await _userPicturesPath;
    return '$userPicturesDir/$kProjectId';
  }

  Future<ProgressPicture> duplicateProgressPicture(
    ProgressPicture progressPicture,
  ) async {
    final newProgressPicture = ProgressPicture(
      file: File(progressPicture.file.path),
    );

    return newProgressPicture;
  }

  Future<File> savePicture(
    ProgressEntry entry,
    ProgressEntryType entryType,
    ProgressPicture picture,
  ) async {
    final saveDirPath = await _saveDirPath;
    final typeSpecificDir = Directory(
      '$saveDirPath/${toFixedDate(entry.date).millisecondsSinceEpoch}/${entryType.name}',
    );

    if (!await typeSpecificDir.exists()) {
      await typeSpecificDir.create(recursive: true);
    }

    // Define a CANONICAL filename for this type.
    // Using entryType.name ensures it's always the same for, e.g., "front".
    // The extension is taken from the source file.
    final String canonicalFileName =
        '${entryType.name}${p.extension(picture.file.path)}';
    final String canonicalFilePath =
        '${typeSpecificDir.path}/$canonicalFileName';
    final File canonicalFile = File(canonicalFilePath);

    // if (await canonicalFile.exists()) {
    //   print("Overwriting existing file at: ${canonicalFile.path}");
    //   await canonicalFile.delete(); // Delete the old one first
    // }

    print(
      "Saving picture for $entryType to: ${canonicalFile.path} from source: ${picture.file.path}",
    );

    // Now copy the new source file to the canonical path
    // Using writeAsBytes is one way; picture.file.copy() is another.
    // picture.file.copy() is often simpler if picture.file is valid.
    try {
      await picture.file.copy(canonicalFile.path);
    } catch (e) {
      print(
        "Error copying file ${picture.file.path} to ${canonicalFile.path}: $e",
      );
      // Fallback or rethrow if needed: writeAsBytes
      // await canonicalFile.writeAsBytes(await sourceFile.readAsBytes());
      rethrow; // Rethrow the error if copy fails
    }

    Logger().i('Saved file to : ${canonicalFile.path}');
    Logger().i(
      'Saved file to : ${canonicalFile.lastModifiedSync().millisecondsSinceEpoch}',
    );
    return canonicalFile;
  }

  DateTime toFixedDate(DateTime start) {
    return DateTime(start.year, start.month, start.day);
  }

  Future<List<ProgressPicture>> listPicturesForEntryType(
    ProgressEntryType type,
  ) async {
    final List<ProgressEntry> entries =
        await ProgressEntriesRepository.listEntries();
    List<ProgressPicture> pictures = [];

    pictures = entries
        .where((ProgressEntry entry) => entry.pictures.containsKey(type))
        .map((ProgressEntry entry) => entry.pictures[type]!)
        .toList();

    return pictures;
  }

  Future<List<Directory>> listEntriesDirectory() async {
    final saveDirPath = await _saveDirPath;
    final List<Directory> directories = [];

    if (!await Directory(saveDirPath).exists()) return directories;
    for (FileSystemEntity fileEntity in Directory(saveDirPath).listSync()) {
      if (await Directory(fileEntity.path).exists()) {
        directories.add(Directory(fileEntity.path));
      }
    }

    return directories;
  }

  Future<Map<ProgressEntryType, ProgressPicture>> getAllEntryTypesFromDate(
    DateTime entryDate,
  ) async {
    final saveDirPath = await _saveDirPath;
    final picturesDirectory = Directory(
      '$saveDirPath/${toFixedDate(entryDate).millisecondsSinceEpoch}',
    );

    final Map<ProgressEntryType, ProgressPicture> result = {};

    if (await picturesDirectory.exists()) {
      for (FileSystemEntity fileEntity in picturesDirectory.listSync()) {
        if (Directory(fileEntity.path).listSync().isNotEmpty) {
          final String entryTypeString = fileEntity.path.split('/').last;
          result[ProgressEntryType.values.byName(
            entryTypeString,
          )] = ProgressPicture(
            file: File(Directory(fileEntity.path).listSync().first.path),
          );
        }
      }
    }

    return result;
  }

  Future<void> deleteEntry(ProgressEntry entry) async {
    final saveDirPath = await _saveDirPath;
    final entryDirectory = Directory(
      '$saveDirPath/${entry.date.millisecondsSinceEpoch}',
    );

    print("Deleting entry folder : $entryDirectory");
    if (await entryDirectory.exists()) {
      await entryDirectory.delete(recursive: true);
    }
  }

  Future<void> deletePicture(
    ProgressEntry entry,
    ProgressEntryType entryType,
  ) async {
    final saveDirPath = await _saveDirPath;
    final entryDirectory = Directory(
      '$saveDirPath/${entry.date.millisecondsSinceEpoch}',
    );
    final pictureDirectory = Directory(
      '${entryDirectory.path}/${entryType.name}',
    );
    if (await pictureDirectory.exists()) {
      await pictureDirectory.delete(recursive: true);
    }
  }
}
