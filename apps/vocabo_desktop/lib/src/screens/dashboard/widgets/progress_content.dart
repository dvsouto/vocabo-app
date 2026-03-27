import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class ProgressContent extends StatelessWidget {
  const ProgressContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: VocaboColors.neutral.withOpacity(0.4),
          ),
          const SizedBox(height: VocaboSpacing.md),
          Text(
            'Under Development',
            style: VocaboTypography.titleLg.copyWith(
              color: VocaboColors.onSurface,
            ),
          ),
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            'Progress tracking is coming soon.\nStay tuned for insights on your learning journey.',
            textAlign: TextAlign.center,
            style: VocaboTypography.bodyMd.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
        ],
      ),
    );
  }
}
