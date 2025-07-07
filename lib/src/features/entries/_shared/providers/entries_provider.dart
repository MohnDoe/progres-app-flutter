import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entry_provider.dart';

final progressEntriesRepositoryProvider = Provider<ProgressEntriesRepository>((
  ref,
) {
  return ProgressEntriesRepository();
});

final progressEntryProvider =
    StateNotifierProvider<ProgressEntryNotifier, ProgressEntry>(
      (ref) => ProgressEntryNotifier(),
    );
