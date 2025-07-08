import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/providers/entries_provider.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';

class ListEntriesController
    extends StateNotifier<AsyncValue<List<ProgressEntry>>> {
  ListEntriesController(this._repository) : super(const AsyncValue.loading()) {
    _entriesSubscription = _repository.entriesStream.listen((entries) {
      state = AsyncValue.data(entries);
    });
    loadEntries();
  }

  final ProgressEntriesRepository _repository;
  late final StreamSubscription _entriesSubscription;

  Future<void> loadEntries() async {
    state = const AsyncValue.loading();
    try {
      await _repository.initEntries();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _entriesSubscription.cancel();
    super.dispose();
  }
}

final listEntriesControllerProvider = StateNotifierProvider<
    ListEntriesController,
    AsyncValue<List<ProgressEntry>>>((ref) {
  final repository = ref.watch(progressEntriesRepositoryProvider);
  return ListEntriesController(repository);
});
