import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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

  Future<File> savePicture(String dirPath, ProgressPicture picture) async {
    final filePath =
        '$dirPath/${picture.date.millisecondsSinceEpoch}${p.extension(picture.file.path)}';

    final newFile = File(filePath);

    await newFile.writeAsBytes(await picture.file.readAsBytes());
    Logger().i('Saved file to : $filePath');
    return newFile;
  }

  Future<List<File>> savePictures(List<ProgressPicture> pictures) async {
    final userPicturesDir = await _userPicturesPath;

    if (!await Directory(userPicturesDir).exists()) {
      await Directory(userPicturesDir).create();
    }

    final dirPath = await _saveDirPath;

    if (!await Directory(dirPath).exists()) {
      await Directory(dirPath).create();
    }

    final List<File> newFiles = [];
    for (ProgressPicture picture in pictures) {
      final newFile = await savePicture(dirPath, picture);
      newFiles.add(newFile);
    }
    return newFiles;
  }

  Future<List<File>> listPictures() async {
    List<File> files = [];
    final filesDir = await _saveDirPath;

    for (FileSystemEntity fileEntity in Directory(filesDir).listSync()) {
      files.add(File(fileEntity.path));
    }

    return files;
  }
}
