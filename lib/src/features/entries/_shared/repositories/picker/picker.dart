import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/picker/ipicker.dart';

class Picker implements IPicker {
  @override
  Future<ProgressPicture?> pickImage(ImageSource source) async {
    final xf = await ImagePicker().pickImage(source: source);
    if (xf != null) {
      return ProgressPicture(file: File(xf.path));
    } else {
      return null;
    }
  }

  Future<List<ProgressPicture>> pickImages() async {
    final List<XFile> files = await ImagePicker().pickMultiImage();
    final List<ProgressPicture> result = [];
    for (XFile xf in files) {
      result.add(ProgressPicture(file: File(xf.path)));
    }

    return result;
  }
}
