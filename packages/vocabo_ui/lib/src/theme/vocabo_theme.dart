import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

abstract final class VocaboTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: VocaboColors.primary,
      onPrimary: VocaboColors.onPrimary,
      primaryContainer: VocaboColors.primaryContainer,
      secondary: VocaboColors.secondary,
      onSecondary: VocaboColors.onSecondary,
      secondaryContainer: VocaboColors.secondary,
      onSecondaryContainer: VocaboColors.onSecondary,
      tertiary: VocaboColors.tertiary,
      surface: VocaboColors.surface,
      onSurface: VocaboColors.onSurface,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      outline: VocaboColors.outlineVariant,
      outlineVariant: VocaboColors.outlineVariant,
      surfaceContainerLowest: VocaboColors.surfaceContainerLowest,
      surfaceContainerLow: VocaboColors.surfaceContainerLow,
      surfaceContainerHigh: VocaboColors.surfaceContainerHigh,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: VocaboColors.surface,
      textTheme: VocaboTypography.textTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VocaboColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: VocaboRadius.sm,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VocaboRadius.sm,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VocaboRadius.sm,
          borderSide: BorderSide(
            color: VocaboColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: VocaboTypography.bodyMd.copyWith(
          color: VocaboColors.neutral,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: VocaboRadius.md,
          ),
          textStyle: VocaboTypography.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: VocaboRadius.md,
          ),
          side: BorderSide(
            color: VocaboColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: VocaboColors.primary,
        ),
      ),
    );
  }
}
