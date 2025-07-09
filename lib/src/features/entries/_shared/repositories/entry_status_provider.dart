import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/entries/list/controllers/list_entries_controller.dart';

final doesEntryExistForDateProvider = Provider.family<bool, DateTime>((
  ref,
  dateToCheck,
) {
  final existingDates = ref.watch(existingEntryDatesProvider);

  final normalizedDateToCheck = DateTime(
    dateToCheck.year,
    dateToCheck.month,
    dateToCheck.day,
  );

  return existingDates.contains(normalizedDateToCheck);
});

final existingEntryDatesProvider = Provider<Set<DateTime>>((ref) {
  final progressEntriesState = ref.watch(listEntriesControllerProvider);

  return progressEntriesState.when(
    data: (entries) {
      return entries.map((entry) {
        return DateTime(entry.date.year, entry.date.month, entry.date.day);
      }).toSet();
    },
    loading: () {
      return <DateTime>{}; // Return an empty set while loading
    },
    error: (err, stack) {
      return <
        DateTime
      >{}; // Return an empty set on error, or handle differently
    },
  );
});
