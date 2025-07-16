import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

enum ProgressEntryType { front, side, back }

class ProgressEntry {
  ProgressEntry({required this.pictures, required this.date});

  final Map<ProgressEntryType, ProgressPicture> pictures;
  final DateTime date;

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
  }) {
    return ProgressEntry(
      pictures: pictures ?? this.pictures,
      date: date ?? this.date,
    );
  }
}
