import 'package:image_picker/image_picker.dart';
import 'package:progres/src/features/pictures/data/repositories/picker.dart';
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

  List<ProgressPicture> orderedPictures() {
    final orderedList = pictures;

    orderedList.sort(
      (ProgressPicture a, ProgressPicture b) => a.date.compareTo(b.date),
    );

    return orderedList;
  }
}

final picturesRepositoryProvider = Provider<PicturesRepository>((ref) {
  return PicturesRepository();
});
