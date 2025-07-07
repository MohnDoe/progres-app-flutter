import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

/// ViewModel for the _add entries screen.
///
/// This class is responsible for managing the state of the entries being added.
/// It extends [StateNotifier] to allow widgets to listen to its state changes.
class AddPicturesViewModel extends StateNotifier<List<ProgressPicture>> {
  /// Creates a new instance of [AddPicturesViewModel].
  ///
  /// It takes an initial list of entries and sets it as the initial state.
  AddPicturesViewModel(super.initialPictures);

  /// Adds a list of entries to the current state.
  void addPictures(List<ProgressPicture> pictures) {
    state = [...state, ...pictures];
  }

  /// Removes a picture from the current state.
  void removePicture(ProgressPicture picture) {
    state = state.where((p) => p != picture).toList();
  }
}

/// Provider for the [AddPicturesViewModel].
///
/// This provider creates an instance of [AddPicturesViewModel] and provides it to the
/// widget tree. It uses the `family` modifier to pass the initial list of entries
/// to the view model.
final addPicturesViewModelProvider = StateNotifierProvider.autoDispose
    .family<AddPicturesViewModel, List<ProgressPicture>, List<ProgressPicture>>(
      (ref, initialPictures) {
        return AddPicturesViewModel(initialPictures);
      },
    );
