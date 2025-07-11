import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // For path manipulation

class FileUtils {
  static Future<Directory> getTemporaryImageDir(String subDirName) async {
    final tempDir = await getTemporaryDirectory();
    final imageTempDir = Directory(p.join(tempDir.path, subDirName));
    if (!await imageTempDir.exists()) {
      await imageTempDir.create(recursive: true);
    }
    return imageTempDir;
  }

  static Future<void> deleteDirectory(Directory directory) async {
    if (await directory.exists()) {
      try {
        await directory.delete(recursive: true);
        print("Deleted directory: ${directory.path}");
      } catch (e) {
        print("Error deleting directory ${directory.path}: $e");
      }
    }
  }

  static Future<String> getAppDocumentsPath(String fileName) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return p.join(appDocDir.path, fileName);
  }

  static Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        await file.delete();
        print("Deleted file: $filePath");
      } catch (e) {
        print("Error deleting file $filePath: $e");
      }
    }
  }

  static Future<void> initDirectory(Directory directory) async {
    print('Initializing directory: ${directory.path}');
    if (!await directory.exists()) {
      print('Directory does not exist, creating: ${directory.path}');
      await directory.create(recursive: true);
      print('Directory created: ${directory.path}');
    }
  }
}
