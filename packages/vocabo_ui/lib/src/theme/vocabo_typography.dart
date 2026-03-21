import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';

abstract final class VocaboTypography {
  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: VocaboColors.onSurface,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static final displayMd = _inter(
    fontSize: 44,
    fontWeight: FontWeight.w700,
  );

  static final headlineSm = _inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static final titleLg = _inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final bodyMd = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static final bodySm = _inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static final labelSm = _inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 11 * 0.05,
  );

  static TextTheme get textTheme => TextTheme(
        displayMedium: displayMd,
        headlineSmall: headlineSm,
        titleLarge: titleLg,
        bodyMedium: bodyMd,
        bodySmall: bodySm,
        labelSmall: labelSm,
      );
}
