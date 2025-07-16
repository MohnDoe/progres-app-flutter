import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

enum ProgressEntryType {
  front,
  side,
  back;

  String get label => switch (this) {
    ProgressEntryType.front => "Front",
    ProgressEntryType.side => "Side",
    ProgressEntryType.back => "Back",
  };
}

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

  static String getLabelFromType(ProgressEntryType type) {
    return type.label;
  }

  ProgressEntry copyWith({
    Map<ProgressEntryType, ProgressPicture>? pictures,
    DateTime? date,
    int? lastModifiedTimestamp,
  }) {
    return ProgressEntry(
      pictures: pictures ?? this.pictures,
      date: date ?? this.date,
    );
  }
}
