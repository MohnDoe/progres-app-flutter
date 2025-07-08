import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_exif/native_exif.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart';

typedef ImportItem = Map<String, Object>;

class ImportControllerNotifier extends StateNotifier<List<ImportItem>> {
  ImportControllerNotifier() : super([]);

  Future<void> saveImport() async {
    //   TODO
  }

  Future<void> addProgressPicture(ProgressPicture picture) async {
    final exifFile = await Exif.fromPath(picture.file.path);
    final pictureOriginalDate = await exifFile.getOriginalDate();

    final importItem = {
      'picture': picture,
      'date': PicturesFileService().toFixedDate(
        pictureOriginalDate ?? DateTime.now(),
      ),
    };

    state = [...state, importItem];
  }

  Future<void> removeProgressPicture(ProgressPicture picture) async {
    state = state.where((item) => item['picture'] != picture).toList();
  }

  Future<void> clearImport() async {
    state = [];
  }
}

final importControllerProvider =
    StateNotifierProvider<ImportControllerNotifier, List<ImportItem>>((ref) {
      return ImportControllerNotifier();
    });
