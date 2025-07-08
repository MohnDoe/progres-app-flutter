import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/repositories/picker/ipicker.dart';

class Picker implements IPicker {
  @override
  Future<ProgressPicture?> pickImage(ImageSource source) async {
    final xf = await ImagePicker().pickImage(source: source);
    print(xf);
    if (xf != null) {
      return ProgressPicture(file: File(xf.path));
    } else {
      return null;
    }
  }
  // static Future<List<ProgressPicture>> selectImages() async {
  //   final files = await ImagePicker().pickMultiImage(requestFullMetadata: true);
  //   final List<ProgressPicture> entries = [];
  //   for (XFile xf in files) {
  //     entries._add(ProgressPicture(file: File(xf.path)));
  //   }
  //
  //   return entries;
  // }

  // static Future<ProgressPicture> toProgressPicture(XFile xf) async {
  //   final file = File(xf.path);
  //   final exif = await Exif.fromPath(xf.path);
  //   final date = await exif.getOriginalDate();
  //
  //   return ProgressPicture(file: file);
  // }
}
