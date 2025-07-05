import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';

import 'package:progres/src/features/pictures/data/repositories/picker.dart';
import 'package:progres/src/features/pictures/data/services/file_service.dart';
import 'package:progres/src/features/pictures/domain/progress_picture.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  List<ProgressPicture> get orderedPictures {
    final orderedList = pictures;

    orderedList.sort(
      (ProgressPicture a, ProgressPicture b) => a.date.compareTo(b.date),
    );

    return orderedList;
  }
}

class UserPicturesRepository extends PicturesRepository {
  Future<void> initPictures() async {
    print('initPictures');
    List<File> files = await PicturesFileService().listPictures();
    pictures = [];
    for (File file in files) {
      pictures = [
        ...pictures,
        ProgressPicture(
          file: file,
          date: DateTime.fromMicrosecondsSinceEpoch(
            int.parse(basenameWithoutExtension(file.path)) * 1000,
          ),
        ),
      ];
    }
  }

  @override
  void removePicture(ProgressPicture picture) {
    // TODO: implement removePicture
    super.removePicture(picture);
  }
}

final picturesRepositoryProvider = Provider<PicturesRepository>((ref) {
  return PicturesRepository();
});

final userPicturesRepositoryProvider = Provider<UserPicturesRepository>((ref) {
  return UserPicturesRepository();
});
