import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboSecondaryButton extends StatelessWidget {
  const VocaboSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: VocaboColors.secondary,
        foregroundColor: VocaboColors.onSecondary,
        minimumSize: isExpanded ? const Size(double.infinity, 44) : const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: VocaboRadius.md),
        textStyle: VocaboTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
