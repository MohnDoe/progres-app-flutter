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

  void movePicture({
    required ProgressEntryType fromType,
    required ProgressEntryType toType,
  }) {
    if (fromType == toType) return; // No action needed

    final currentPictures = Map<ProgressEntryType, ProgressPicture>.from(
      state.pictures,
    );

    final pictureToMove = currentPictures[fromType];

    if (pictureToMove == null) {
      // Should not happen if onWillAccept is implemented correctly, but good for safety
      print(
        "Attempted to move a picture from $fromType, but it has no picture.",
      );
      return;
    }

    // Get the picture currently at the target destination (if any)
    final ProgressPicture? pictureAtTarget = currentPictures[toType];

    // Create the new pictures map
    final newPictures = Map<ProgressEntryType, ProgressPicture>.from(
      currentPictures,
    );

    // Perform the swap/move:
    newPictures[toType] =
        pictureToMove; // Place the dragged picture at the target type

    if (pictureAtTarget != null) {
      newPictures[fromType] = pictureAtTarget;
    } else {
      newPictures.remove(fromType);
    }

    state = state.copyWith(pictures: newPictures);
  }
}

final progressEntryStateNotifierProvider =
    StateNotifierProvider<ProgressEntryNotifier, ProgressEntry>(
      (ref) => ProgressEntryNotifier(),
    );
