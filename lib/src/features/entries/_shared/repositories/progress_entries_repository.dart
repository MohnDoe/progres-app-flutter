import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/core/services/file_service.dart'
    show PicturesFileService;

class ProgressEntriesRepository {
  List<ProgressEntry> entries = [];

  List<ProgressEntry> get orderedEntries {
    final orderedList = List<ProgressEntry>.from(
      entries,
    ); // Create a new list to avoid modifying the original

    orderedList.sort(
      (ProgressEntry a, ProgressEntry b) => a.date.compareTo(b.date),
    );

    return orderedList;
  }

  Future<void> initEntries() async {}
}
