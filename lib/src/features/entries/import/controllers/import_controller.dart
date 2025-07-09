import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:native_exif/native_exif.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/core/services/file_service.dart';

class ImportItem {
  ImportItem({required this.picture, this.type, required this.date});
  final ProgressPicture picture;
  final ProgressEntryType? type;
  final DateTime date;
}

class ImportControllerNotifier extends StateNotifier<List<ImportItem>> {
  ImportControllerNotifier() : super([]);

  void saveImport() async {
    state = [];
  }

  Future<void> addProgressPicture(ProgressPicture picture) async {
    final exifFile = await Exif.fromPath(picture.file.path);
    final pictureOriginalDate = await exifFile.getOriginalDate();

    if (state.any((item) => item.picture == picture)) {
      return;
    }

    final importItem = ImportItem(
      picture: picture,
      type: null,
      date: PicturesFileService().toFixedDate(
        pictureOriginalDate ?? DateTime.now(),
      ),
    );

    state = [...state, importItem];
  }

  void removeProgressPicture(ProgressPicture picture) async {
    state = state.where((item) => item.picture != picture).toList();
  }

  void clearImport() async {
    state = [];
  }

  void removePictureFromImports(ProgressPicture picture) async {
    state = state.where((item) => item.picture != picture).toList();
  }

  void removeDay(DateTime date) {
    state = state
        .where((ImportItem entry) => !entry.date.isAtSameMomentAs(date))
        .toList();
  }

  void updatePictureEntryType(
    ProgressPicture picture,
    ProgressEntryType entryType,
  ) {
    final correspondingItem = state.firstWhere(
      (item) => item.picture == picture,
    );
    final correspondingItemIndex = state.indexOf(correspondingItem);
    final newImportItem = ImportItem(
      picture: correspondingItem.picture,
      date: correspondingItem.date,
      type: entryType,
    );

    final newState = List<ImportItem>.from(state);
    newState[correspondingItemIndex] = newImportItem;
    state = newState;
  }
}

final importControllerProvider =
    StateNotifierProvider<ImportControllerNotifier, List<ImportItem>>((ref) {
      return ImportControllerNotifier();
    });
