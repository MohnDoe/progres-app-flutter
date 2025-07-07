import 'package:progres/src/core/domain/models/progress_picture.dart';

enum ProgressEntryType { front, side, back }

class ProgressEntry {
  ProgressEntry({required this.picture, required this.date});

  final Map<ProgressEntryType, ProgressPicture> picture;
  final DateTime date;
}
