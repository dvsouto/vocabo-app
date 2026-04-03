import 'dart:ui';

abstract final class VocaboColors {
  // --- Primary palette (scale) ---
  static const primary50 = Color(0xFFE5F1FF);
  static const primary100 = Color(0xFFCCE3FF);
  static const primary200 = Color(0xFF99C7FF);
  static const primary300 = Color(0xFF66ABFF);
  static const primary400 = Color(0xFF339AFF);
  static const primary = Color(0xFF007AFF);       // 500 — base accent
  static const primary500 = primary;
  static const primary600 = Color(0xFF0070EB);
  static const primary700 = Color(0xFF0058BC);     // buttons
  static const primary800 = Color(0xFF00408A);
  static const primary900 = Color(0xFF002B5C);

  static const primaryContainer = primary600;

  // --- Secondary palette ---
  static const secondary = Color(0xFF5856D6);

  // --- Tertiary palette ---
  static const tertiary = Color(0xFF34C759);
  static const tertiaryFixed = Color(0xFF72FE88);

  // --- Neutral palette (scale) ---
  static const neutral50 = Color(0xFFF5F5F5);
  static const neutral100 = Color(0xFFE8E8EA);
  static const neutral200 = Color(0xFFD1D1D4);
  static const neutral300 = Color(0xFFBABABE);
  static const neutral400 = Color(0xFFA4A4A8);
  static const neutral = Color(0xFF8E8E93);        // 500 — base
  static const neutral500 = neutral;
  static const neutral600 = Color(0xFF6E6E73);
  static const neutral700 = Color(0xFF4E4E53);
  static const neutral800 = Color(0xFF333336);
  static const neutral900 = Color(0xFF1C1C1E);

  // --- Surfaces ---
  static const surface = Color(0xFFFAF9FE);
  static const surfaceContainerLow = Color(0xFFF4F3F8);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerHigh = Color(0xFFECEBF0);

  // --- On-colors ---
  static const onSurface = Color(0xFF1A1B1F);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onSecondary = Color(0xFFFFFBFF);

  // --- Outline ---
  static const outlineVariant = Color(0xFFC1C6D7);
}
