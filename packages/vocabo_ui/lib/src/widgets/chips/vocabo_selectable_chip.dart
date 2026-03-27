import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboSelectableChip extends StatelessWidget {
  const VocaboSelectableChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = enabled && onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: effectiveEnabled ? onTap : null,
        mouseCursor: effectiveEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        borderRadius: VocaboRadius.sm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? VocaboColors.primary
                : VocaboColors.surfaceContainerLow,
            borderRadius: VocaboRadius.sm,
          ),
          child: Text(
            label.toUpperCase(),
            style: VocaboTypography.labelSm.copyWith(
              color: isSelected ? VocaboColors.onPrimary : VocaboColors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
