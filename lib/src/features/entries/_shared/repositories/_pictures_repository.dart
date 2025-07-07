// import 'dart:io';
//
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart';
//
// import 'package:progres/src/core/domain/models/progress_picture.dart';
// import 'package:progres/src/core/services/file_service.dart';
// import 'package:progres/src/features/pictures/_shared/repositories/picker.dart';

//
// class PicturesRepository {
//   List<ProgressPicture> entries = [];
//
//   void addPictures(List<ProgressPicture> pics) {
//     entries = [...entries, ...pics];
//   }
//
//   void addPicture(ProgressPicture picture) {
//     entries = [...entries, picture];
//   }
//
//   void removePicture(ProgressPicture picture) {
//     entries.remove(picture);
//   }
//
//   Future<List<ProgressPicture>> handleXFiles(List<XFile> files) async {
//     for (XFile xf in files) {
//       final progressPicture = await Picker.toProgressPicture(xf);
//       addPicture(progressPicture);
//     }
//     return entries;
//   }
//
//   /// Returns a new list of entries sorted by date in ascending order.
//   /// The original `entries` list remains unchanged.
//   List<ProgressPicture> get orderedPictures {
//     final orderedList = List<ProgressPicture>.from(entries); // Create a new list to avoid modifying the original
//
//     orderedList.sort(
//       (ProgressPicture a, ProgressPicture b) => a.date.compareTo(b.date),
//     );
//
//     return orderedList;
//   }
// }
//
// class UserPicturesRepository extends PicturesRepository {
//   Future<void> initPictures() async {
//     List<File> files = await PicturesFileService().listPictures();
//     entries = files.map((file) => ProgressPicture(
//           file: file,
//           date: DateTime.fromMicrosecondsSinceEpoch(
//             int.parse(basenameWithoutExtension(file.path)) * 1000,
//           ),
//         )).toList();
//   }
//
//   @override
//   void removePicture(ProgressPicture picture) {
//     super.removePicture(picture);
//     // Also delete the file from storage
//     if (picture.file.existsSync()) {
//       picture.file.deleteSync();
//     }
//   }
// }
