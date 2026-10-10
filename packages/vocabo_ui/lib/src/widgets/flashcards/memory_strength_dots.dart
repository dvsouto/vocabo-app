import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

/// A row of dots showing how strong a word is in memory, optionally with
/// the strength name next to it.
class MemoryStrengthDots extends StatelessWidget {
  const MemoryStrengthDots({
    super.key,
    required this.strength,
    this.showLabel = true,
    this.dotSize = 6,
    this.color,
  });

  final MemoryStrength strength;
  final bool showLabel;
  final double dotSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final filledColor =
        color ??
        (strength.isMastered ? VocaboColors.tertiary : VocaboColors.primary);

    return Semantics(
      label:
          '${strength.name}, ${strength.level} of ${MemoryStrength.totalLevels}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < MemoryStrength.totalLevels; i++) ...[
            if (i > 0) SizedBox(width: dotSize * 0.5),
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < strength.level
                    ? filledColor
                    : VocaboColors.neutral200,
              ),
            ),
          ],
          if (showLabel) ...[
            SizedBox(width: dotSize * 1.5),
            Text(
              strength.name.toUpperCase(),
              style: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
