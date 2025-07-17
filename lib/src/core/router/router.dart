import 'package:go_router/go_router.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/import/views/import_screen.dart';
import 'package:progres/src/features/entries/import/views/import_screen.dart';
import 'package:progres/src/features/entries/import/views/import_screen.dart';
import 'package:progres/src/features/entries/list/views/list_entries_screen.dart';
import 'package:progres/src/features/gallery/views/gallery_screen.dart';

final router = GoRouter(
  initialLocation: ListEntriesScreen.path,
  routes: [
    GoRoute(
      name: GalleryScreen.name,
      path: GalleryScreen.path,
      builder: (context, state) => GalleryScreen(
        currentEntry: state.extra as ProgressEntry,
        entryType: ProgressEntryType.values.firstWhere(
          (element) => element.name == state.pathParameters['entryType'],
        ),
        mode: GalleryMode.values.firstWhere(
          (element) => element.name == state.pathParameters['mode'],
        ),
      ),
    ),
    GoRoute(
      name: ListEntriesScreen.name,
      path: ListEntriesScreen.path,
      builder: (context, state) => const ListEntriesScreen(),
    ),
    GoRoute(
      name: ImportScreen.name,
      path: ImportScreen.path,
      builder: (context, state) => const ImportScreen(),
    ),
  ],
);
