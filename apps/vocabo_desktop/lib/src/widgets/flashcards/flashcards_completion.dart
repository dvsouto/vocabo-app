import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/dashboard_providers.dart';
import 'package:vocabo_desktop/src/providers/flashcard_providers.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/claim_focus.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcard_evaluation_bar.dart';

/// Builds the one-line summary shown at the end of a session.
String sessionSummary(
  AppLocalizations l10n, {
  required int reviewed,
  required int clear,
}) {
  final clearPart = switch (clear) {
    0 => l10n.flashcardsSummaryNoneClear,
    _ when clear == reviewed && reviewed > 1 => l10n.flashcardsSummaryAllClear,
    _ when clear == reviewed => l10n.flashcardsSummaryOneClear,
    _ => l10n.flashcardsSummarySomeClear(clear),
  };
  return '${l10n.flashcardsSummaryRecalled(reviewed)} $clearPart';
}

/// End of session note: what was reviewed, how clear it felt and which
/// words come back later today.
class FlashcardsCompletion extends ConsumerWidget {
  const FlashcardsCompletion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = flashcardDeckSessionProvider(
      ref.watch(currentFlashcardDeckProvider),
    );
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final l10n = context.l10n;
    final cards = state.session?.cards ?? const <FlashcardSessionCard>[];
    final blankTerms = cards
        .where((card) => card.evaluation == FlashcardEvaluation.hard)
        .map((card) => card.flashcard.term)
        .where((term) => term.isNotEmpty)
        .toList();

    void seeProgress() {
      ref.read(dashboardSectionProvider.notifier).state =
          DashboardSection.progress;
      notifier.finishCompletion();
    }

    return ClaimFocus(
      debugLabel: 'flashcards-completion',
      onKeyEvent: (node, event) {
        final isEnter =
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter;
        if (event is KeyDownEvent && isEnter) {
          notifier.finishCompletion();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(VocaboSpacing.xxl),
              decoration: BoxDecoration(
                color: VocaboColors.surfaceContainerLow,
                borderRadius: VocaboRadius.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.flashcardsSessionNote,
                    style: VocaboTypography.labelSm.copyWith(
                      color: VocaboColors.neutral,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: VocaboSpacing.sm),
                  Text(
                    l10n.flashcardsSessionComplete,
                    style: VocaboTypography.headlineSm,
                  ),
                  const SizedBox(height: VocaboSpacing.sm),
                  Text(
                    sessionSummary(
                      l10n,
                      reviewed: state.evaluatedCount,
                      clear: state.countOf(FlashcardEvaluation.easy),
                    ),
                    style: VocaboTypography.bodyMd.copyWith(
                      color: VocaboColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: VocaboSpacing.xl),
                  Row(
                    children: [
                      for (final evaluation in FlashcardEvaluation.values) ...[
                        if (evaluation != FlashcardEvaluation.hard)
                          const SizedBox(width: VocaboSpacing.md),
                        Expanded(
                          child: _ClarityCount(
                            evaluation: evaluation,
                            value: state.countOf(evaluation),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (blankTerms.isNotEmpty) ...[
                    const SizedBox(height: VocaboSpacing.xl),
                    Text(
                      l10n.flashcardsComingBackLaterToday,
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: VocaboSpacing.sm),
                    Wrap(
                      spacing: VocaboSpacing.sm,
                      runSpacing: VocaboSpacing.sm,
                      children: [
                        for (final term in blankTerms)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: VocaboColors.surfaceContainerLowest,
                              borderRadius: VocaboRadius.sm,
                            ),
                            child: Text(
                              term,
                              style: VocaboTypography.bodyMd.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: VocaboSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: VocaboPrimaryButton(
                          label: l10n.flashcardsBackToFlashcards,
                          isExpanded: true,
                          trailing: VocaboKeyCap(
                            l10n.flashcardsKeyEnter,
                            color: VocaboColors.onPrimary,
                          ),
                          onPressed: notifier.finishCompletion,
                        ),
                      ),
                      const SizedBox(width: VocaboSpacing.md),
                      VocaboTextButton(
                        label: l10n.flashcardsSeeProgress,
                        onPressed: seeProgress,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClarityCount extends StatelessWidget {
  const _ClarityCount({required this.evaluation, required this.value});

  final FlashcardEvaluation evaluation;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = evaluationPalette(context, evaluation);

    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.md),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: VocaboRadius.md,
      ),
      child: Row(
        children: [
          ClarityIcon(
            clarity: clarityOf(evaluation),
            color: palette.foreground,
          ),
          const SizedBox(width: VocaboSpacing.sm),
          Text(
            '$value',
            style: VocaboTypography.titleLg.copyWith(color: palette.foreground),
          ),
          const SizedBox(width: VocaboSpacing.xs),
          Flexible(
            child: Text(
              context.l10n.clarityLabel(evaluation),
              overflow: TextOverflow.ellipsis,
              style: VocaboTypography.bodySm.copyWith(
                color: palette.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
