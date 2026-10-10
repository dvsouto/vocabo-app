import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class _EvaluationOption {
  const _EvaluationOption({
    required this.evaluation,
    required this.label,
    required this.icon,
    required this.shortcut,
  });

  final FlashcardEvaluation evaluation;
  final String label;
  final IconData icon;
  final String shortcut;
}

const _options = [
  _EvaluationOption(
    evaluation: FlashcardEvaluation.hard,
    label: "Didn't recall",
    icon: Icons.thumb_down_outlined,
    shortcut: '1',
  ),
  _EvaluationOption(
    evaluation: FlashcardEvaluation.medium,
    label: 'Almost',
    icon: Icons.thumb_up_outlined,
    shortcut: '2',
  ),
  _EvaluationOption(
    evaluation: FlashcardEvaluation.easy,
    label: 'Recalled',
    icon: Icons.thumb_up_alt_rounded,
    shortcut: '3',
  ),
];

class FlashcardEvaluationBar extends StatelessWidget {
  const FlashcardEvaluationBar({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onEvaluate,
  });

  final FlashcardEvaluation? selected;
  final bool enabled;
  final ValueChanged<FlashcardEvaluation> onEvaluate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const SizedBox(width: VocaboSpacing.md),
          Expanded(
            child: _EvaluationButton(
              index: i,
              option: _options[i],
              isSelected: selected == _options[i].evaluation,
              isDimmed: selected != null && selected != _options[i].evaluation,
              onTap: enabled ? () => onEvaluate(_options[i].evaluation) : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _EvaluationButton extends StatelessWidget {
  const _EvaluationButton({
    required this.index,
    required this.option,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
  });

  final int index;
  final _EvaluationOption option;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback? onTap;

  ({Color foreground, Color background, Color selectedBackground}) _palette(
    BuildContext context,
  ) {
    return switch (option.evaluation) {
      FlashcardEvaluation.hard => (
        foreground: Theme.of(context).colorScheme.error,
        background: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        selectedBackground: Theme.of(
          context,
        ).colorScheme.error.withValues(alpha: 0.2),
      ),
      FlashcardEvaluation.medium => (
        foreground: VocaboColors.onSurface,
        background: VocaboColors.surfaceContainerHigh,
        selectedBackground: VocaboColors.neutral200,
      ),
      FlashcardEvaluation.easy => (
        foreground: const Color(0xFF1E8E3E),
        background: VocaboColors.tertiary.withValues(alpha: 0.12),
        selectedBackground: VocaboColors.tertiary.withValues(alpha: 0.28),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Interval(index * 0.15, 1, curve: Curves.easeOutBack),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDimmed ? 0.3 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: isSelected ? 1.06 : 1,
          child: Material(
            color: isSelected ? palette.selectedBackground : palette.background,
            borderRadius: VocaboRadius.md,
            child: InkWell(
              onTap: onTap,
              borderRadius: VocaboRadius.md,
              mouseCursor: onTap == null
                  ? SystemMouseCursors.basic
                  : SystemMouseCursors.click,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: VocaboSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(option.icon, size: 20, color: palette.foreground),
                    const SizedBox(width: VocaboSpacing.sm),
                    Flexible(
                      child: Text(
                        option.label,
                        overflow: TextOverflow.ellipsis,
                        style: VocaboTypography.bodyMd.copyWith(
                          color: palette.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: VocaboSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: palette.foreground.withValues(alpha: 0.1),
                        borderRadius: VocaboRadius.sm,
                      ),
                      child: Text(
                        option.shortcut,
                        style: VocaboTypography.labelSm.copyWith(
                          color: palette.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
