import 'package:flutter/material.dart';

import '../game/model/resources.dart';

/// Dark navy space theme. Low saturation surfaces for long sessions,
/// saturated accents only for resources and actionable buttons.
abstract final class OrbitColors {
  static const background = Color(0xFF070E22);
  static const surface = Color(0xFF0F1A3A);
  static const surfaceHigh = Color(0xFF172552);
  static const outline = Color(0xFF26376B);
  static const primary = Color(0xFF4FC3F7);
  static const accent = Color(0xFFFFC857);
  static const success = Color(0xFF5BE49B);
  static const danger = Color(0xFFFF6B6B);
  static const textDim = Color(0xFF8C9BC4);

  static Color resource(ResourceType r) => switch (r) {
        ResourceType.ore => const Color(0xFFB8A48C),
        ResourceType.energy => const Color(0xFFFFD54F),
        ResourceType.alloy => const Color(0xFF80DEEA),
        ResourceType.research => const Color(0xFFCE93D8),
      };
}

abstract final class OrbitIcons {
  static IconData resource(ResourceType r) => switch (r) {
        ResourceType.ore => Icons.terrain,
        ResourceType.energy => Icons.bolt,
        ResourceType.alloy => Icons.view_in_ar,
        ResourceType.research => Icons.science,
      };

  static IconData facility(String icon) => switch (icon) {
        'ore' => Icons.construction,
        'energy' => Icons.solar_power,
        'alloy' => Icons.local_fire_department,
        'research' => Icons.biotech,
        'storage' => Icons.warehouse,
        _ => Icons.factory,
      };
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: OrbitColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: OrbitColors.primary,
    secondary: OrbitColors.accent,
    surface: OrbitColors.surface,
    surfaceContainerHighest: OrbitColors.surfaceHigh,
    outline: OrbitColors.outline,
    error: OrbitColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: OrbitColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: OrbitColors.background,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: OrbitColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: OrbitColors.outline),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: OrbitColors.surface,
      indicatorColor: OrbitColors.surfaceHigh,
      height: 64,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 44), // comfortable touch target
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
