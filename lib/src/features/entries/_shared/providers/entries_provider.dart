import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';

final progressEntriesRepositoryProvider = Provider<ProgressEntriesRepository>((
  ref,
) {
  return ProgressEntriesRepository();
});
