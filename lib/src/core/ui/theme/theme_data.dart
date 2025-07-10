import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
/// Use same major flex_color_scheme package version. If you use a
/// lower minor version, some properties may not be supported.
/// In that case, remove them after copying this theme to your
/// app or upgrade the package to version 8.2.0.
///
/// Use it in a [MaterialApp] like this:
///
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
/// );
abstract final class AppTheme {
  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
    // User defined custom colors made with FlexSchemeColor() API.
    colors: const FlexSchemeColor(
      primary: Color(0xFF004881),
      primaryContainer: Color(0xFFD0E4FF),
      secondary: Color(0xFFAC3306),
      secondaryContainer: Color(0xFFFFDBCF),
      tertiary: Color(0xFF006875),
      tertiaryContainer: Color(0xFF95F0FF),
      appBarColor: Color(0xFFFFDBCF),
      error: Color(0xFFBA1A1A),
      errorContainer: Color(0xFFFFDAD6),
    ),
    // Component theme configurations for light mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      defaultRadius: 8.0,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    // ColorScheme seed generation configuration for light mode.
    keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData dark = FlexThemeData.dark(
    // User defined custom colors made with FlexSchemeColor() API.
    colors: const FlexSchemeColor(
      primary: Color(0xFFFFEF94),
      primaryContainer: Color(0xFFFFD900),
      primaryLightRef: Color(0xFF004881), // The color of light mode primary
      secondary: Color(0xFFFFE5E6),
      secondaryContainer: Color(0xFFFF7477),
      secondaryLightRef: Color(0xFFAC3306), // The color of light mode secondary
      tertiary: Color(0xFFE8E6F8),
      tertiaryContainer: Color(0xFFB4ADEA),
      tertiaryLightRef: Color(0xFF006875), // The color of light mode tertiary
      appBarColor: Color(0xFFFFDBCF),
      error: Color(0xFFFFB4AB),
      errorContainer: Color(0xFF93000A),
    ),
    // Surface color adjustments.
    surfaceMode: FlexSurfaceMode.level,
    blendLevel: 1,
    // Component theme configurations for dark mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnLevel: 1,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      defaultRadius: 8.0,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationRailUseIndicator: true,
    ),
    // ColorScheme seed configuration setup for dark mode.
    keyColors: const FlexKeyColors(
      useSecondary: true,
      useTertiary: true,
      keepPrimary: true,
      keepSecondary: true,
      keepTertiary: true,
      keepPrimaryContainer: true,
      keepSecondaryContainer: true,
      keepTertiaryContainer: true,
    ),
    // Direct ThemeData properties.
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
