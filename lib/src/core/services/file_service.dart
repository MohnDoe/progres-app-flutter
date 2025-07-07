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

  Future<File> savePicture(ProgressEntry entry, ProgressPicture picture) async {
    final saveDirPath = await _saveDirPath;

    final filePath =
        '$saveDirPath/${entry.date.millisecondsSinceEpoch}${p.extension(picture.file.path)}';

    final newFile = File(filePath);

    await newFile.writeAsBytes(await picture.file.readAsBytes());
    Logger().i('Saved file to : $filePath');
    return newFile;
  }

  // Future<void> _createDirectory(String directoryPath) async {
  //   if (!await Directory(directoryPath).exists()) {
  //     await Directory(directoryPath).create();
  //   }
  // }

  // Future<List<File>> savePictures(List<ProgressPicture> entries) async {
  //   final userPicturesDir = await _userPicturesPath;
  //   await _createDirectory(userPicturesDir);
  //
  //   final List<File> newFiles = [];
  //   for (ProgressPicture picture in entries) {
  //     final newFile = await savePicture(picture);
  //     newFiles._add(newFile);
  //   }
  //   return newFiles;
  // }

  Future<List<File>> listPictures(ProgressEntryType type) async {
    List<File> files = [];
    final filesDir = "${await _saveDirPath}/$type";

    for (FileSystemEntity fileEntity in Directory(filesDir).listSync()) {
      files.add(File(fileEntity.path));
    }

    return files;
  }
}
