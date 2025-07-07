import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';
import 'package:progres/src/features/entries/_shared/providers/entries_provider.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';

/// ViewModel for the entries list screen.
///
/// This class is responsible for managing the state of the entries list,
/// including loading the entries from the repository and handling loading/error states.
/// It extends [StateNotifier] to allow widgets to listen to its state changes.
class ListEntriesViewModel
    extends StateNotifier<AsyncValue<List<ProgressEntry>>> {
  /// Creates a new instance of [ListEntriesViewModel].
  ///
  /// It takes a [ProgressEntriesRepository] as a dependency and initializes the state
  /// to loading, then immediately calls [loadEntries].
  ListEntriesViewModel(this._repository) : super(const AsyncValue.loading()) {
    loadEntries();
  }

  final ProgressEntriesRepository _repository;

  /// Loads the entries from the repository and updates the state.
  ///
  /// Sets the state to loading, then tries to fetch the entries.
  /// If successful, the state is updated with the data.
  /// If an error occurs, the state is updated with the error.
  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      await _repository.initEntries();
      state = AsyncValue.data(_repository.orderedEntries);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for the [ListEntriesViewModel].
///
/// This provider creates an instance of [ListEntriesViewModel] and provides it to the
/// widget tree. It depends on the [userPicturesRepositoryProvider] to get the
/// repository instance.
final picturesViewModelProvider =
    StateNotifierProvider<
      ListEntriesViewModel,
      AsyncValue<List<ProgressEntry>>
    >((ref) {
      final repository = ref.watch(progressEntriesRepositoryProvider);
      return ListEntriesViewModel(repository);
    });
