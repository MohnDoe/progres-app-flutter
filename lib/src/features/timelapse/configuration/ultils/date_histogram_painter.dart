import 'package:flutter/material.dart';

class DateHistogramPainter extends CustomPainter {
  final List<DateTime> datesWithEntry;
  final List<DateTime> highlightedDates;
  final DateTime firstDate;
  final DateTime lastDate;
  final int totalDays;
  final Color color;
  final Color highlightColor;

  DateHistogramPainter({
    required this.datesWithEntry,
    required this.highlightedDates,
    required this.firstDate,
    required this.lastDate,
    required this.totalDays,
    required this.color,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double dotSpacing = size.width / totalDays;

    final double radius = 2;
    final double radiusHighlighted = 4;

    for (int i = 0; i < totalDays + 1; i++) {
      final currentDate = firstDate.add(Duration(days: i));
      final bool hasEntry = datesWithEntry.any(
        (date) => date.isAtSameMomentAs(
          DateTime(currentDate.year, currentDate.month, currentDate.day),
        ),
      );
      if (hasEntry) {
        final bool isHighlighted = highlightedDates.any(
          (date) => date.isAtSameMomentAs(
            DateTime(currentDate.year, currentDate.month, currentDate.day),
          ),
        );
        final paint = Paint()
          ..color = isHighlighted ? highlightColor : color
          ..style = PaintingStyle.fill;
        final center = Offset((i * dotSpacing) + (dotSpacing / 2), size.height / 2);

        canvas.drawCircle(center, isHighlighted ? radiusHighlighted : radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DateHistogramPainter oldDelegate) {
    return oldDelegate.datesWithEntry != datesWithEntry ||
        oldDelegate.firstDate != firstDate ||
        oldDelegate.lastDate != lastDate ||
        oldDelegate.totalDays != totalDays ||
        oldDelegate.highlightedDates != highlightedDates;
  }
}
