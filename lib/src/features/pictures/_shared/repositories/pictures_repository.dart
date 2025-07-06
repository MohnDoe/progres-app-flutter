import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart';
import 'package:progres/src/features/pictures/_shared/repositories/picker.dart';

class PicturesRepository {
  List<ProgressPicture> pictures = [];

  void addPictures(List<ProgressPicture> pics) {
    pictures = [...pictures, ...pics];
  }

  void addPicture(ProgressPicture picture) {
    pictures = [...pictures, picture];
  }

  void removePicture(ProgressPicture picture) {
    pictures.remove(picture);
  }

  Future<List<ProgressPicture>> handleXFiles(List<XFile> files) async {
    for (XFile xf in files) {
      final progressPicture = await Picker.toProgressPicture(xf);
      addPicture(progressPicture);
    }
    return pictures;
  }

  /// Returns a new list of pictures sorted by date in ascending order.
  /// The original `pictures` list remains unchanged.
  List<ProgressPicture> get orderedPictures {
    final orderedList = List<ProgressPicture>.from(pictures); // Create a new list to avoid modifying the original

    orderedList.sort(
      (ProgressPicture a, ProgressPicture b) => a.date.compareTo(b.date),
    );

    return orderedList;
  }
}

class UserPicturesRepository extends PicturesRepository {
  Future<void> initPictures() async {
    List<File> files = await PicturesFileService().listPictures();
    pictures = files.map((file) => ProgressPicture(
          file: file,
          date: DateTime.fromMicrosecondsSinceEpoch(
            int.parse(basenameWithoutExtension(file.path)) * 1000,
          ),
        )).toList();
  }

  @override
  void removePicture(ProgressPicture picture) {
    super.removePicture(picture);
    // Also delete the file from storage
    if (picture.file.existsSync()) {
      picture.file.deleteSync();
    }
  }
}
