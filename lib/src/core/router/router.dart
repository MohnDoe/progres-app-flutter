import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:progres/src/core/domain/models/progress_entry.dart';
import 'package:progres/src/features/entries/import/views/import_screen.dart';
import 'package:progres/src/features/entries/list/views/list_entries_screen.dart';
import 'package:progres/src/features/gallery/views/gallery_screen.dart';
import 'package:progres/src/features/timelapse/configuration/views/timelapse_configuration_screen.dart';
import 'package:progres/src/features/timelapse/generation/view/generation_screen.dart';
import 'package:progres/src/features/timelapse/player/view/video_player_screen.dart';

final router = GoRouter(
  initialLocation: ListEntriesScreen.path,
  // initialLocation: '${VideoPlayerScreen.path}/front/1643807972/1753103972',
  routes: [
    GoRoute(
      name: GalleryScreen.name,
      path: GalleryScreen.path,
      pageBuilder: (context, state) => CustomTransitionPage(
        child: GalleryScreen(
          currentEntry: state.extra as ProgressEntry,
          entryType: ProgressEntryType.values.firstWhere(
            (element) => element.name == state.pathParameters['entryType'],
          ),
          mode: GalleryMode.values.firstWhere(
            (element) => element.name == state.pathParameters['mode'],
          ),
        ),
        transitionDuration: Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
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
    GoRoute(
      name: GenerationScreen.name,
      path: GenerationScreen.path,
      builder: (context, state) => const GenerationScreen(),
    ),
    GoRoute(
      path: TimelapseConfigurationScreen.path,
      name: TimelapseConfigurationScreen.name,
      builder: (context, state) => const TimelapseConfigurationScreen(),
    ),
    GoRoute(
      name: VideoPlayerScreen.name,
      path: VideoPlayerScreen.path + VideoPlayerScreen.pathParams,
      builder: (context, state) => VideoPlayerScreen(
        type: ProgressEntryType.values.firstWhere(
          (element) => element.name == state.pathParameters['type'],
        ),
        from: DateTime.fromMillisecondsSinceEpoch(
          int.parse(state.pathParameters['from']!) * 1000,
        ),
        to: DateTime.fromMillisecondsSinceEpoch(
          int.parse(state.pathParameters['to']!) * 1000,
        ),
      ),
    ),
  ],
);
