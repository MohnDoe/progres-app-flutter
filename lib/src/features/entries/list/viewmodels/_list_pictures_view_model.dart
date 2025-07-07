// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:progres/src/core/domain/models/progress_picture.dart';
// import 'package:progres/src/features/entries/_shared/providers/pictures_providers.dart';
// import 'package:progres/src/features/pictures/_shared/repositories/_pictures_repository.dart';
//
// /// ViewModel for the entries list screen.
// ///
// /// This class is responsible for managing the state of the entries list,
// /// including loading the entries from the repository and handling loading/error states.
// /// It extends [StateNotifier] to allow widgets to listen to its state changes.
// class PicturesViewModel
//     extends StateNotifier<AsyncValue<List<ProgressPicture>>> {
//   /// Creates a new instance of [PicturesViewModel].
//   ///
//   /// It takes a [UserPicturesRepository] as a dependency and initializes the state
//   /// to loading, then immediately calls [loadPictures].
//   PicturesViewModel(this._repository) : super(const AsyncValue.loading()) {
//     loadPictures();
//   }
//
//   final UserPicturesRepository _repository;
//
//   /// Loads the entries from the repository and updates the state.
//   ///
//   /// Sets the state to loading, then tries to fetch the entries.
//   /// If successful, the state is updated with the data.
//   /// If an error occurs, the state is updated with the error.
//   Future<void> loadPictures() async {
//     state = const AsyncValue.loading();
//     try {
//       await _repository.initPictures();
//       state = AsyncValue.data(_repository.orderedPictures);
//     } catch (e, st) {
//       state = AsyncValue.error(e, st);
//     }
//   }
//
//   Future<void> removePicture(ProgressPicture picture) async {
//     state = const AsyncValue.loading();
//     try {
//       _repository.removePicture(picture);
//       state = AsyncValue.data(_repository.orderedPictures);
//     } catch (e, st) {
//       state = AsyncValue.error(e, st);
//     }
//   }
// }
//
// /// Provider for the [PicturesViewModel].
// ///
// /// This provider creates an instance of [PicturesViewModel] and provides it to the
// /// widget tree. It depends on the [userPicturesRepositoryProvider] to get the
// /// repository instance.
// final picturesViewModelProvider =
//     StateNotifierProvider<PicturesViewModel, AsyncValue<List<ProgressPicture>>>(
//       (ref) {
//         final repository = ref.watch(userPicturesRepositoryProvider);
//         return PicturesViewModel(repository);
//       },
//     );
