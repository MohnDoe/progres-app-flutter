import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/_shared/repositories/progress_entries_repository.dart';
import 'package:progres/src/features/timelapse/configuration/ultils/date_histogram_painter.dart';

class DateHistogram extends ConsumerWidget {
  const DateHistogram({
    super.key,
    required this.selectedFirstDate,
    required this.selectedLastDate,
    required this.entries,
    required this.validEntriesDates,
    required this.dotColor,
    required this.dotRadius,
    required this.validDotColor,
    required this.validDotRadius,
    required this.highlightedDotColor,
    required this.highlightedDotRadius,
  });

  final DateTime selectedFirstDate;
  final DateTime selectedLastDate;

  final List<DateTime> entries;
  final List<DateTime> validEntriesDates;

  final double dotRadius;
  final Color dotColor;

  final double highlightedDotRadius;
  final Color highlightedDotColor;

  final double validDotRadius;
  final Color validDotColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstDate = entries.last;
    final lastDate = entries.first;
    final totalDays = lastDate.difference(firstDate).inDays + 1;

    final List<DateTime> highlightedDates = [];
    for (final entry in entries) {
      final date = DateTime(entry.year, entry.month, entry.day);
      if (date.isBefore(selectedLastDate) && date.isAfter(selectedFirstDate) ||
          date.isAtSameMomentAs(selectedFirstDate) ||
          date.isAtSameMomentAs(selectedLastDate)) {
        highlightedDates.add(date);
      }
    }

    // datesWithEntry.sort();

    // TODO : change color when type is selector
    // only available are primary for selected type

    return RepaintBoundary(
      child: CustomPaint(
        willChange: false,
        isComplex: true,
        size: Size(double.infinity, 8),
        painter: DateHistogramPainter(
          allEntriesDates: entries,
          allValidEntriesDates: validEntriesDates,
          allSelectedEntriesDates: highlightedDates,
          firstDate: firstDate,
          lastDate: lastDate,
          totalDays: totalDays,

          color: dotColor,
          radius: dotRadius,

          highlightColor: highlightedDotColor,
          highlightedRadius: highlightedDotRadius,

          validColor: validDotColor,
          validRadius: validDotRadius,
        ),
      ),
    );
  }
}
