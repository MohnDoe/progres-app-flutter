import 'package:progres/src/core/domain/models/progress_picture.dart';

enum ProgressEntryType { front, side, back }

class ProgressEntry {
  ProgressEntry({required this.pictures, required this.date});

  final Map<ProgressEntryType, ProgressPicture> pictures;
  final DateTime date;
}
