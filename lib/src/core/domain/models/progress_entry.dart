import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

enum ProgressEntryType { front, side, back }

class ProgressEntry {
  ProgressEntry({
    required this.pictures,
    required this.date,
    required this.lastModifiedTimestamp,
  });

  final Map<ProgressEntryType, ProgressPicture> pictures;
  final DateTime date;
  final int lastModifiedTimestamp;

  static FaIcon getIconFromType(ProgressEntryType type) {
    return switch (type) {
      ProgressEntryType.front => FaIcon(FontAwesomeIcons.childReaching),
      ProgressEntryType.side => FaIcon(FontAwesomeIcons.personWalking),
      ProgressEntryType.back => FaIcon(FontAwesomeIcons.person),
    };
  }

  ProgressEntry copyWith({
    Map<ProgressEntryType, ProgressPicture>? pictures,
    DateTime? date,
    int? lastModifiedTimestamp,
  }) {
    return ProgressEntry(
      pictures: pictures ?? this.pictures,
      date: date ?? this.date,
      lastModifiedTimestamp:
          lastModifiedTimestamp ?? this.lastModifiedTimestamp,
    );
  }
}
