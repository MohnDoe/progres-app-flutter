import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

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

  Future<File> savePicture(
    ProgressEntry entry,
    ProgressEntryType entryType,
    ProgressPicture picture,
  ) async {
    final saveDirPath = await _saveDirPath;
    final destinationDirectory = Directory(
      '$saveDirPath/${toFixedDate(entry.date).millisecondsSinceEpoch}/${entryType.name}',
    );

    if (!await destinationDirectory.exists()) {
      await destinationDirectory.create(recursive: true);
    }

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
    final filesDir = "${await _saveDirPath}/$type";

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
        final String entryTypeString = fileEntity.path.split('/').last;
        result[ProgressEntryType.values.byName(
          entryTypeString,
        )] = ProgressPicture(
          file: File(Directory(fileEntity.path).listSync().first.path),
        );
      }
    }

    return result;
  }
}
