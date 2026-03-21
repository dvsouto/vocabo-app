import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';

abstract final class VocaboShadows {
  static final whisper = BoxShadow(
    color: VocaboColors.onSurface.withValues(alpha: 0.04),
    blurRadius: 32,
    spreadRadius: 0,
    offset: const Offset(0, 8),
  );
}
