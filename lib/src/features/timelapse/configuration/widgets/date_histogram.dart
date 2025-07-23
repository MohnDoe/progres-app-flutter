import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/timelapse/configuration/ultils/date_histogram_painter.dart';

class DateHistogram extends ConsumerWidget {
  const DateHistogram({
    super.key,
    required this.selectedFirstDate,
    required this.selectedLastDate,
    required this.dotColor,
    required this.highlightedDotColor,
  });

  final DateTime selectedFirstDate;
  final DateTime selectedLastDate;

  final Color dotColor;
  final Color highlightedDotColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.read(progressEntriesRepositoryProvider).orderedEntries;

    final firstDate = entries.last.date;
    final lastDate = entries.first.date;
    final totalDays = lastDate.difference(firstDate).inDays + 1;

    final List<DateTime> datesWithEntry = [];
    final List<DateTime> highlightedDates = [];
    for (final entry in entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (!datesWithEntry.contains(date)) {
        datesWithEntry.add(date);

        if (date.isBefore(selectedLastDate) && date.isAfter(selectedFirstDate) ||
            date.isAtSameMomentAs(selectedFirstDate) ||
            date.isAtSameMomentAs(selectedLastDate)) {
          highlightedDates.add(date);
        }
      }
    }
    if (datesWithEntry.isEmpty) {
      return const SizedBox.shrink();
    }

    datesWithEntry.sort();

    // TODO : change color when type is selector
    // only available are primary for selected type

    return RepaintBoundary(
      child: CustomPaint(
        willChange: false,
        isComplex: true,
        size: Size(double.infinity, 8),
        painter: DateHistogramPainter(
          datesWithEntry: datesWithEntry,
          highlightedDates: highlightedDates,
          firstDate: firstDate,
          lastDate: lastDate,
          totalDays: totalDays,
          highlightColor: highlightedDotColor,
          color: dotColor,
        ),
      ),
    );
  }
}
