import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:progres/src/core/services/font_service.dart';
import 'package:progres/src/core/ui/theme/theme_data.dart';

import 'package:progres/src/core/router/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FontService.setupFFmpegFontDirectory();
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp.router(
      routerConfig: router,
      title: 'Progrès',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
    );
  }
}
