import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboSocialAuthButton extends StatelessWidget {
  const VocaboSocialAuthButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: VocaboColors.surfaceContainerLowest,
        foregroundColor: VocaboColors.onSurface,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: VocaboRadius.sm),
        side: BorderSide(
          color: VocaboColors.outlineVariant.withValues(alpha: 0.15),
        ),
        textStyle: VocaboTypography.bodyMd.copyWith(fontWeight: FontWeight.w500),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
