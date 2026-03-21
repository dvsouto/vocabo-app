import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_shadows.dart';
import 'package:vocabo_ui/src/theme/vocabo_spacing.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.padding,
  });

  final Widget child;
  final double? width;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: VocaboRadius.xl,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: width,
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: VocaboSpacing.xl,
                vertical: VocaboSpacing.xxl,
              ),
          decoration: BoxDecoration(
            color: VocaboColors.surface.withValues(alpha: 0.8),
            borderRadius: VocaboRadius.xl,
            boxShadow: [VocaboShadows.whisper],
          ),
          child: child,
        ),
      ),
    );
  }
}
