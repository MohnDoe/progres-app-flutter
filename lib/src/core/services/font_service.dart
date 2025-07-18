import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FontService {
  // You can make this a service or a utility class
  static bool _fontsCopied = false;
  static String? _appFontDirectory;

  static Future<String> getAppFontDirectoryPath() async {
    if (_appFontDirectory == null) {
      final Directory cacheDir =
          await getTemporaryDirectory(); // Or getApplicationDocumentsDirectory()
      _appFontDirectory = p.join(cacheDir.path, 'app_fonts');
    }
    return _appFontDirectory!;
  }

  static Future<void> copyFontsFromAssets() async {
    if (_fontsCopied) {
      Logger().i('Fonts already copied.');
      return;
    }

    try {
      final String appFontDirPath = await getAppFontDirectoryPath();
      final Directory appFontDir = Directory(appFontDirPath);

      if (!await appFontDir.exists()) {
        await appFontDir.create(recursive: true);
        Logger().i('Created app font directory: $appFontDirPath');
      }

      // List files in assets/fonts/
      // This part is a bit tricky as you can't directly list asset directories.
      // You need to know the names of your font files beforehand,
      // or list them in a manifest file (e.g., a JSON file in assets).

      // Let's assume you know your font names:
      final List<String> fontAssetNames = [
        'Roboto-Regular.ttf',
        // 'DejaVuSans.ttf', // Add all your font filenames here
        // 'YourOtherFont.otf',
      ];

      for (String fontAssetName in fontAssetNames) {
        final String destinationFontPath = p.join(
          appFontDirPath,
          fontAssetName,
        );
        final File destinationFile = File(destinationFontPath);

        if (!await destinationFile.exists()) {
          // Copy only if it doesn't exist
          try {
            final ByteData data = await rootBundle.load(
              'assets/fonts/$fontAssetName',
            );
            final List<int> bytes = data.buffer.asUint8List(
              data.offsetInBytes,
              data.lengthInBytes,
            );
            await destinationFile.writeAsBytes(bytes, flush: true);
            Logger().i('Copied font $fontAssetName to $destinationFontPath');
          } catch (e) {
            Logger().e('Failed to copy font $fontAssetName: $e');
            // Decide if this is a fatal error for your app
          }
        } else {
          Logger().i(
            'Font $fontAssetName already exists at $destinationFontPath',
          );
        }
      }
      _fontsCopied = true;
    } catch (e) {
      Logger().e('Error in copyFontsFromAssets: $e');
      _fontsCopied = false; // Ensure we retry if it failed globally
    }
  }

  static Future<void> setupFFmpegFontDirectory() async {
    await copyFontsFromAssets(); // Make sure fonts are copied

    if (_fontsCopied && _appFontDirectory != null) {
      // It's good practice to also include system font directories if possible,
      // though access might be restricted on newer Android versions.
      // Common Android system font paths (might not all be accessible or exist):
      final List<String> fontDirectories = [
        _appFontDirectory!, // YOUR APP'S FONT DIRECTORY MUST BE FIRST OR EARLY!
        "/system/fonts",
        "/system/font",
        "/data/fonts",
        // Add more known system paths if needed, but prioritize your app's bundled fonts.
      ];

      // Remove duplicates and non-existent directories before passing to FFmpegKit
      final List<String> validFontDirectories = [];
      for (String dirPath in fontDirectories.toSet()) {
        // toSet() for uniqueness
        final dir = Directory(dirPath);
        if (await dir.exists()) {
          // Check if directory actually exists
          validFontDirectories.add(dirPath);
        }
      }

      if (validFontDirectories.isEmpty &&
          _appFontDirectory != null &&
          await Directory(_appFontDirectory!).exists()) {
        // If no system dirs were found/valid, ensure at least our app's font dir is there
        validFontDirectories.add(_appFontDirectory!);
      }

      Logger().i("Setting FFmpeg font directories to: $validFontDirectories");
      // FFmpegKitConfig.setFontDirectoryList expects a List<String>.
      FFmpegKitConfig.setFontDirectoryList(validFontDirectories);

      // Optional: If you have a custom fonts.conf file for fontconfig
      // String fontConfigPath = await copyFontConfigFromAssets(); // You'd need a similar copy function
      // FFmpegKitConfig.setFontconfigConfigurationPath(fontConfigPath);

      Logger().i('FFmpeg font directories set.');
    } else {
      Logger().w(
        'Could not set FFmpeg font directories: Fonts not copied or app font directory not set.',
      );
    }
  }
}
