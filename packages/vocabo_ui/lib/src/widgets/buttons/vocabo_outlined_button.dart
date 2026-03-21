import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';

class VocaboOutlinedButton extends StatelessWidget {
  const VocaboOutlinedButton({
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
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: VocaboColors.onSurface,
        minimumSize: isExpanded ? const Size(double.infinity, 44) : const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: VocaboRadius.md),
        side: BorderSide(
          color: VocaboColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(label),
    );
  }
}
