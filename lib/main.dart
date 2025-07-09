import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/ui/theme/theme_data.dart';
import 'package:progres/src/features/entries/list/views/list_entries_screen.dart';

void main() {
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Progrès',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: ListEntriesScreen(),
    );
  }
}
