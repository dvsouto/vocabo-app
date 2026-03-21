import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

enum TagChipVariant { mastered, learning, outlined }

class VocaboTagChip extends StatelessWidget {
  const VocaboTagChip({
    super.key,
    required this.label,
    this.variant = TagChipVariant.outlined,
  });

  final String label;
  final TagChipVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: switch (variant) {
          TagChipVariant.mastered => VocaboColors.tertiary,
          TagChipVariant.learning => VocaboColors.primary.withValues(alpha: 0.1),
          TagChipVariant.outlined => VocaboColors.surfaceContainerLow,
        },
        borderRadius: VocaboRadius.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: VocaboTypography.labelSm.copyWith(
          color: switch (variant) {
            TagChipVariant.mastered => Colors.white,
            TagChipVariant.learning => VocaboColors.primary,
            TagChipVariant.outlined => VocaboColors.onSurface,
          },
        ),
      ),
    );
  }
}
