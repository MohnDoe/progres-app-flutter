import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/utils/file_utils.dart';

const kProjectId = '1';

class PicturesFileService {
  Future<String> get _userPicturesPath async {
    return await FileUtils.getAppDocumentsPath('user_pictures');
  }

  Future<String> get _saveDirPath async {
    final userPicturesDirPath = await _userPicturesPath;
    return p.join(userPicturesDirPath, kProjectId);
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
    final destinationDirectory = Directory(
      '$saveDirPath/${toFixedDate(entry.date).millisecondsSinceEpoch}/${entryType.name}',
    );

    await FileUtils.initDirectory(destinationDirectory);

    final filename = '${entryType.name}${p.extension(picture.file.path)}';

    final filePath = '${destinationDirectory.path}/$filename';

    final newFile = File(filePath);

    await newFile.writeAsBytes(await picture.file.readAsBytes());
    Logger().i('Saved file to : $filePath');
    return newFile;
  }

  DateTime toFixedDate(DateTime start) {
    return DateTime(start.year, start.month, start.day);
  }

  Future<List<File>> listPictures(ProgressEntryType type) async {
    List<File> files = [];
    final filesDir = "${await _saveDirPath}/${type.name}";

    for (FileSystemEntity fileEntity in Directory(filesDir).listSync()) {
      files.add(File(fileEntity.path));
    }

    return files;
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

  static Future<File?> getFileFromEntryDirectory(
    Directory entryDirectory,
    ProgressEntryType type,
  ) async {
    if (!await entryDirectory.exists()) return null;

    final Directory entryTypeDirectory = Directory(
      "${entryDirectory.path}/${type.name}",
    );
    if (!await entryTypeDirectory.exists()) return null;

    List<FileSystemEntity> fileSystemEntities = entryTypeDirectory.listSync();

    if (fileSystemEntities.isNotEmpty) {
      return File(fileSystemEntities.first.path);
    }

    return null;
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

    await FileUtils.deleteDirectory(entryDirectory);
  }
}
