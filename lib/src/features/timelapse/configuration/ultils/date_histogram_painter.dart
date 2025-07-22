import 'package:flutter/material.dart';

class DateHistogramPainter extends CustomPainter {
  final List<DateTime> datesWithEntry;
  final DateTime firstDate;
  final DateTime lastDate;
  final int totalDays;
  final Color color;
  final Color borderColor;

  DateHistogramPainter({
    required this.datesWithEntry,
    required this.firstDate,
    required this.lastDate,
    required this.totalDays,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // final paintBorder = Paint()
    //   ..color = borderColor
    //   ..strokeWidth = 1
    //   ..style = PaintingStyle.stroke;

    final double dotSpacing = size.width / totalDays;

    final double radius = 4;

    for (int i = 0; i < totalDays; i++) {
      final currentDate = firstDate.add(Duration(days: i));
      final bool hasEntry = datesWithEntry.any(
        (date) => date.isAtSameMomentAs(
          DateTime(currentDate.year, currentDate.month, currentDate.day),
        ),
      );
      if (hasEntry) {
        final center = Offset((i * dotSpacing) + (dotSpacing / 2), size.height / 2);

        canvas.drawCircle(center, radius, paint);
        // canvas.drawCircle(center, radius, paintBorder);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DateHistogramPainter oldDelegate) {
    return oldDelegate.datesWithEntry != datesWithEntry ||
        oldDelegate.firstDate != firstDate ||
        oldDelegate.lastDate != lastDate ||
        oldDelegate.totalDays != totalDays;
  }
}
