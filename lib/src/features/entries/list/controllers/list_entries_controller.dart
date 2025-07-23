import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';

class ListEntriesController extends StateNotifier<AsyncValue<List<ProgressEntry>>> {
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

  int getEntriesCount({DateTime? from, DateTime? to, ProgressEntryType? type}) {
    return _repository.getEntriesCount(from: from, to: to, type: type);
  }

  Map<ProgressEntryType, int> getEntriesCountByEntryType({DateTime? from, DateTime? to}) {
    final Map<ProgressEntryType, int> result = {};
    for (ProgressEntryType type in ProgressEntryType.values) {
      result[type] = getEntriesCount(from: from, to: to, type: type);
    }
    return result;
  }

  Map<ProgressEntryType, List<ProgressEntry>> getEntriesGroupedByType({
    DateTime? from,
    DateTime? to,
  }) {
    final Map<ProgressEntryType, List<ProgressEntry>> result = {};
    for (ProgressEntryType type in ProgressEntryType.values) {
      result[type] = getEntriesBetweenDates(from: from, to: to, type: type);
    }
    return result;
  }

  List<ProgressEntry> getEntriesBetweenDates({
    DateTime? from,
    DateTime? to,
    ProgressEntryType? type,
  }) {
    return _repository.getEntriesBetweenDates(from: from, to: to, type: type);
  }

  @override
  void dispose() {
    _entriesSubscription.cancel();
    super.dispose();
  }
}

final listEntriesControllerProvider =
    StateNotifierProvider<ListEntriesController, AsyncValue<List<ProgressEntry>>>((ref) {
      final repository = ref.watch(progressEntriesRepositoryProvider);
      return ListEntriesController(repository);
    });
