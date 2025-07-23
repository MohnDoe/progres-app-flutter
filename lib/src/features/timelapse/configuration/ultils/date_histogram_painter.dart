import 'package:flutter/material.dart';

class DateHistogramPainter extends CustomPainter {
  DateHistogramPainter({
    required this.allEntriesDates,
    required this.allValidEntriesDates,
    required this.allSelectedEntriesDates,
    required this.firstDate,
    required this.lastDate,
    required this.totalDays,
    required this.color,
    required this.highlightColor,
    required this.validColor,
    required this.validRadius,
    required this.radius,
    required this.highlightedRadius,
  });

  final List<DateTime> allEntriesDates;
  final List<DateTime> allValidEntriesDates;
  final List<DateTime> allSelectedEntriesDates;
  final DateTime firstDate;
  final DateTime lastDate;
  final int totalDays;

  final double radius;
  final Color color;

  final Color highlightColor;
  final double highlightedRadius;

  final Color validColor;
  final double validRadius;

  @override
  void paint(Canvas canvas, Size size) {
    print(allValidEntriesDates);
    final double dotSpacing = size.width / totalDays;

    for (int i = 0; i < totalDays + 1; i++) {
      Color dotColor = color;
      double dotRadius = radius;

      final currentDate = firstDate.add(Duration(days: i));

      final bool hasEntry = allEntriesDates.any(
        (date) => date.isAtSameMomentAs(
          DateTime(currentDate.year, currentDate.month, currentDate.day),
        ),
      );

      if (hasEntry) {
        final bool isValidEntry = allValidEntriesDates.any(
          (date) => date.isAtSameMomentAs(
            DateTime(currentDate.year, currentDate.month, currentDate.day),
          ),
        );

        final bool isHighlighted =
            isValidEntry &&
            allSelectedEntriesDates.any(
              (date) => date.isAtSameMomentAs(
                DateTime(currentDate.year, currentDate.month, currentDate.day),
              ),
            );

        if (isValidEntry) {
          dotColor = validColor;
          dotRadius = validRadius;
        }

        if (isHighlighted) {
          dotColor = highlightColor;
          dotRadius = highlightedRadius;
        }

        final paint = Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;
        final center = Offset((i * dotSpacing) + (dotSpacing / 2), size.height / 2);

        canvas.drawCircle(center, dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DateHistogramPainter oldDelegate) {
    return oldDelegate.allEntriesDates != allEntriesDates ||
        oldDelegate.allValidEntriesDates != allValidEntriesDates ||
        oldDelegate.firstDate != firstDate ||
        oldDelegate.lastDate != lastDate ||
        oldDelegate.totalDays != totalDays ||
        oldDelegate.allSelectedEntriesDates != allSelectedEntriesDates;
  }
}
