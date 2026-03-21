import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboLanguageChipGroup extends StatelessWidget {
  const VocaboLanguageChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = option == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: VocaboLanguageChip(
            label: option,
            isSelected: isSelected,
            onTap: () => onSelected(option),
          ),
        );
      }).toList(),
    );
  }
}

class VocaboLanguageChip extends StatelessWidget {
  const VocaboLanguageChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? VocaboColors.primary
              : VocaboColors.surfaceContainerLow,
          borderRadius: VocaboRadius.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                size: 16,
                color: VocaboColors.onPrimary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: VocaboTypography.bodyMd.copyWith(
                color: isSelected
                    ? VocaboColors.onPrimary
                    : VocaboColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
