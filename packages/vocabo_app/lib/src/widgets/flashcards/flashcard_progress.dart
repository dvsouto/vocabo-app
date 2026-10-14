import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class FlashcardProgress extends StatelessWidget {
  const FlashcardProgress({
    super.key,
    required this.current,
    required this.total,
  });

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Text(
          '$current/$total',
          style: VocaboTypography.titleLg.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),
        ClipRRect(
          borderRadius: VocaboRadius.sm,
          child: Container(
            height: 4,
            color: VocaboColors.neutral200,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                widthFactor: fraction,
                child: Container(color: VocaboColors.onSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
