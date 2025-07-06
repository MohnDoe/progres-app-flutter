import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:native_exif/native_exif.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class Picker {
  static Future<List<ProgressPicture>> selectImages() async {
    final files = await ImagePicker().pickMultiImage(requestFullMetadata: true);
    final List<ProgressPicture> pictures = [];
    for (XFile file in files) {
      pictures.add(await Picker.toProgressPicture(file));
    }

    return pictures;
  }

  static Future<ProgressPicture> toProgressPicture(XFile xf) async {
    final file = File(xf.path);
    final exif = await Exif.fromPath(xf.path);
    final date = await exif.getOriginalDate();

    return ProgressPicture(file: file, date: date!);
  }
}
