import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/providers/entries_provider.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';

class ListEntriesViewModel
    extends StateNotifier<AsyncValue<List<ProgressEntry>>> {
  ListEntriesViewModel(this._repository) : super(const AsyncValue.loading()) {
    loadEntries();
  }

  final ProgressEntriesRepository _repository;

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

final picturesViewModelProvider =
    StateNotifierProvider<
      ListEntriesViewModel,
      AsyncValue<List<ProgressEntry>>
    >((ref) {
      final repository = ref.watch(progressEntriesRepositoryProvider);
      return ListEntriesViewModel(repository);
    });
