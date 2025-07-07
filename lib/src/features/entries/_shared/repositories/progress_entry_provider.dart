import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/domain/models/progress_picture.dart';

class ProgressEntryNotifier extends StateNotifier<ProgressEntry> {
  ProgressEntryNotifier()
    : super(ProgressEntry(pictures: {}, date: DateTime.now()));

  void setProgressPictureToType(
    ProgressEntryType entryType,
    ProgressPicture progressPicture,
  ) {
    print('hello from setProgressPictureToType');
    state = ProgressEntry(
      pictures: {...state.pictures, entryType: progressPicture},
      date: state.date,
    );
  }
}
