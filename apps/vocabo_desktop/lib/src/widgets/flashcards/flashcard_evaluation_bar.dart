import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';

class _EvaluationOption {
  const _EvaluationOption({
    required this.evaluation,
    required this.clarity,
    required this.shortcut,
  });

  final FlashcardEvaluation evaluation;
  final Clarity clarity;
  final String shortcut;
}

const _options = [
  _EvaluationOption(
    evaluation: FlashcardEvaluation.hard,
    clarity: Clarity.blank,
    shortcut: '1',
  ),
  _EvaluationOption(
    evaluation: FlashcardEvaluation.medium,
    clarity: Clarity.fuzzy,
    shortcut: '2',
  ),
  _EvaluationOption(
    evaluation: FlashcardEvaluation.easy,
    clarity: Clarity.clear,
    shortcut: '3',
  ),
];

const _clearGreen = Color(0xFF1E8E3E);

/// Palette shared with the session note so each answer keeps one color.
({Color foreground, Color background, Color selectedBackground})
evaluationPalette(BuildContext context, FlashcardEvaluation evaluation) {
  final error = Theme.of(context).colorScheme.error;
  return switch (evaluation) {
    FlashcardEvaluation.hard => (
      foreground: error,
      background: error.withValues(alpha: 0.08),
      selectedBackground: error.withValues(alpha: 0.2),
    ),
    FlashcardEvaluation.medium => (
      foreground: VocaboColors.onSurface,
      background: VocaboColors.surfaceContainerHigh,
      selectedBackground: VocaboColors.neutral200,
    ),
    FlashcardEvaluation.easy => (
      foreground: _clearGreen,
      background: VocaboColors.tertiary.withValues(alpha: 0.12),
      selectedBackground: VocaboColors.tertiary.withValues(alpha: 0.28),
    ),
  };
}

Clarity clarityOf(FlashcardEvaluation evaluation) =>
    _options.firstWhere((option) => option.evaluation == evaluation).clarity;

class FlashcardEvaluationBar extends StatelessWidget {
  const FlashcardEvaluationBar({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onEvaluate,
    required this.stageIndex,
    required this.stages,
    this.compact = false,
  });

  final FlashcardEvaluation? selected;
  final bool enabled;
  final ValueChanged<FlashcardEvaluation> onEvaluate;

  /// Current stage of the card, used to tell when each answer brings it back.
  final int stageIndex;
  final List<int> stages;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0)
            SizedBox(width: compact ? VocaboSpacing.sm : VocaboSpacing.md),
          Expanded(
            child: _EvaluationButton(
              index: i,
              option: _options[i],
              caption: l10n.nextReviewCaption(
                _options[i].evaluation,
                stageIndex: stageIndex,
                stages: stages,
              ),
              compact: compact,
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
    required this.caption,
    required this.compact,
    required this.isSelected,
    required this.isDimmed,
    required this.onTap,
  });

  final int index;
  final _EvaluationOption option;
  final String caption;
  final bool compact;
  final bool isSelected;
  final bool isDimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = evaluationPalette(context, option.evaluation);

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
                height: compact ? 54 : 64,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? VocaboSpacing.sm : VocaboSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClarityIcon(
                      clarity: option.clarity,
                      color: palette.foreground,
                      size: compact ? 14 : 18,
                    ),
                    SizedBox(width: compact ? 6 : VocaboSpacing.sm),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.clarityLabel(option.evaluation),
                            overflow: TextOverflow.ellipsis,
                            style: VocaboTypography.bodyMd.copyWith(
                              color: palette.foreground,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            caption,
                            overflow: TextOverflow.ellipsis,
                            style: VocaboTypography.bodySm.copyWith(
                              color: palette.foreground.withValues(alpha: 0.7),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: VocaboSpacing.sm),
                      VocaboKeyCap(option.shortcut, color: palette.foreground),
                    ],
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
