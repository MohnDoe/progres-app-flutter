import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class ProgressEntryNotifier extends StateNotifier<ProgressEntry> {
  ProgressEntryNotifier()
    : super(ProgressEntry(pictures: {}, date: DateTime.now()));

  void setProgressPictureToType(
    ProgressEntryType entryType,
    ProgressPicture progressPicture,
  ) {
    state = ProgressEntry(
      pictures: {...state.pictures, entryType: progressPicture},
      date: state.date,
    );
  }

  void setEntry(ProgressEntry entry) => state = entry;

  void setDate(DateTime date) {
    state = ProgressEntry(pictures: state.pictures, date: date);
  }

  void removePicture(ProgressEntryType entryType) {
    final newPictures = Map.of(state.pictures);
    newPictures.remove(entryType);

    state = ProgressEntry(pictures: newPictures, date: state.date);
  }

  void reset() {
    state = ProgressEntry(pictures: {}, date: DateTime.now());
  }
}

final progressEntryStateNotifierProvider =
    StateNotifierProvider<ProgressEntryNotifier, ProgressEntry>(
      (ref) => ProgressEntryNotifier(),
    );
