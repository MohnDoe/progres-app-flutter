import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';

/// Provider that checks if an entry already exists for a given date.
/// It takes a DateTime parameter (which will be normalized to midnight).
final doesEntryExistForDateProvider = Provider.family<bool, DateTime>((
  ref,
  dateToCheck,
) {
  final normalizedDateToCheck = DateTime(
    dateToCheck.year,
    dateToCheck.month,
    dateToCheck.day,
  );

  return ref
      .watch(progressEntriesRepositoryProvider)
      .entries
      .map((ProgressEntry entry) => entry.date)
      .contains(normalizedDateToCheck);
});
