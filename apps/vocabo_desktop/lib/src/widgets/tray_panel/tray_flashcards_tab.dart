import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

/// Cards per round in the menu bar panel. A session left open in the main
/// window is resumed in full instead.
const quickSessionSize = 3;

/// Quick flashcards round from the menu bar panel, without opening the app.
class TrayFlashcardsTab extends ConsumerWidget {
  const TrayFlashcardsTab({super.key, required this.onOpenFlashcards});

  /// Opens the main window on the Flashcards section.
  final VoidCallback onOpenFlashcards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(flashcardSessionProvider.select((s) => s.phase));

    return switch (phase) {
      FlashcardsPhase.home => _TrayHome(onOpenFlashcards: onOpenFlashcards),
      FlashcardsPhase.loading => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      FlashcardsPhase.session => const _TraySession(),
      FlashcardsPhase.completion => _TrayCompletion(
        onOpenFlashcards: onOpenFlashcards,
      ),
    };
  }
}

class _TrayHome extends ConsumerWidget {
  const _TrayHome({required this.onOpenFlashcards});

  final VoidCallback onOpenFlashcards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(flashcardStatusProvider);
    final notifier = ref.read(flashcardSessionProvider.notifier);

    Widget body = status.when(
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => _TrayMessage(
        title: l10n.trayFlashcardsUnavailable,
        subtitle: l10n.trayFlashcardsCheckConnection,
        action: VocaboTextButton(
          label: l10n.commonRetry,
          onPressed: () => ref.invalidate(flashcardStatusProvider),
        ),
      ),
      data: (summary) {
        if (summary.canStartSession) {
          return _TrayMessage(
            title: summary.hasActiveSession
                ? l10n.trayFlashcardsSessionInProgress
                : l10n.trayFlashcardsWordsWaiting(summary.dueCount),
            subtitle: summary.hasActiveSession
                ? l10n.trayFlashcardsResumeHint
                : l10n.trayFlashcardsQuickRoundHint(quickSessionSize),
            action: VocaboPrimaryButton(
              label: summary.hasActiveSession
                  ? l10n.trayFlashcardsContinueReviewing
                  : l10n.trayFlashcardsQuickSession,
              isExpanded: true,
              onPressed: () => notifier.startSession(size: quickSessionSize),
            ),
          );
        }

        if (summary.isWaiting) {
          return _TrayMessage(
            title: l10n.trayFlashcardsMemoryGood,
            subtitle: l10n.trayFlashcardsNextWordsIn,
            action: FlashcardCountdown(
              target: summary.nextReviewAt!,
              style: VocaboTypography.headlineSm,
              onFinished: () => ref.invalidate(flashcardStatusProvider),
            ),
          );
        }

        return _TrayMessage(
          title: l10n.trayFlashcardsEmptyTitle,
          subtitle: l10n.trayFlashcardsEmptyBody,
        );
      },
    );

    return Column(
      children: [
        Expanded(child: body),
        VocaboTextButton(
          label: l10n.trayFlashcardsOpen,
          onPressed: onOpenFlashcards,
        ),
      ],
    );
  }
}

class _TrayMessage extends StatelessWidget {
  const _TrayMessage({
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: VocaboSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: VocaboColors.primary50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.style_outlined,
                color: VocaboColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: VocaboSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: VocaboTypography.titleLg,
            ),
            const SizedBox(height: VocaboSpacing.xs),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: VocaboSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _TraySession extends ConsumerStatefulWidget {
  const _TraySession();

  @override
  ConsumerState<_TraySession> createState() => _TraySessionState();
}

class _TraySessionState extends ConsumerState<_TraySession> {
  // The Add Word search field keeps focus across tabs, so the session claims
  // it explicitly for its keyboard shortcuts.
  final _focusNode = FocusNode(debugLabel: 'tray-flashcards-session');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  static final _evaluationKeys = <LogicalKeyboardKey, FlashcardEvaluation>{
    LogicalKeyboardKey.digit1: FlashcardEvaluation.hard,
    LogicalKeyboardKey.digit2: FlashcardEvaluation.medium,
    LogicalKeyboardKey.digit3: FlashcardEvaluation.easy,
  };

  /// Flipping or answering rebuilds the card and can drop keyboard focus;
  /// take it back so the shortcuts keep working.
  void _reclaimFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(flashcardSessionProvider, (previous, next) {
      if (previous?.isFlipped != next.isFlipped ||
          previous?.currentIndex != next.currentIndex) {
        _reclaimFocus();
      }
    });
    final state = ref.watch(flashcardSessionProvider);
    final notifier = ref.read(flashcardSessionProvider.notifier);
    final card = state.currentCard;
    final stages =
        ref.watch(flashcardConfigProvider).valueOrNull?.stages ??
        FlashcardConfig.fallback.stages;

    final interactive = !state.isSubmitting;
    final progress = state.totalCards == 0
        ? 0.0
        : state.evaluatedCount / state.totalCards;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent || card == null) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.space && !state.isFlipped) {
          notifier.flip();
          return KeyEventResult.handled;
        }
        final evaluation = _evaluationKeys[event.logicalKey];
        if (evaluation != null && state.isFlipped) {
          notifier.evaluate(evaluation);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      // The focus node stays mounted while the card changes, so the
      // shortcuts keep working between cards.
      child: card == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: context.l10n.trayFlashcardsStop,
                      icon: const Icon(Icons.close, size: 18),
                      color: VocaboColors.neutral,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: notifier.leaveSession,
                    ),
                    const SizedBox(width: VocaboSpacing.xs),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: VocaboRadius.sm,
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          color: VocaboColors.onSurface,
                          backgroundColor: VocaboColors.neutral200,
                        ),
                      ),
                    ),
                    const SizedBox(width: VocaboSpacing.sm),
                    Text(
                      '${state.evaluatedCount}/${state.totalCards}',
                      style: VocaboTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VocaboSpacing.sm),
                Expanded(
                  child: SingleChildScrollView(
                    child: FlashcardCard(
                      key: ValueKey(card.id),
                      card: card,
                      compact: true,
                      isFlipped: state.isFlipped,
                      isExpanded: state.isExpanded,
                      enabled: interactive,
                      onFlip: notifier.flip,
                      onToggleMeaning: notifier.toggleMeaning,
                    ),
                  ),
                ),
                const SizedBox(height: VocaboSpacing.sm),
                state.isFlipped
                    ? FlashcardEvaluationBar(
                        key: ValueKey('tray-evaluate-${card.id}'),
                        selected: state.selectedEvaluation,
                        enabled: interactive,
                        onEvaluate: notifier.evaluate,
                        stageIndex: card.flashcard.currentStageIndex,
                        stages: stages,
                        compact: true,
                      )
                    : VocaboPrimaryButton(
                        key: ValueKey('tray-continue-${card.id}'),
                        label: context.l10n.commonContinue,
                        isExpanded: true,
                        onPressed: interactive ? notifier.flip : null,
                      ),
              ],
            ),
    );
  }
}

class _TrayCompletion extends ConsumerWidget {
  const _TrayCompletion({required this.onOpenFlashcards});

  final VoidCallback onOpenFlashcards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(flashcardSessionProvider);
    final notifier = ref.read(flashcardSessionProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: _TrayMessage(
            title: l10n.trayFlashcardsRoundComplete,
            subtitle: sessionSummary(
              context.l10n,
              reviewed: state.evaluatedCount,
              clear: state.countOf(FlashcardEvaluation.easy),
            ),
            action: VocaboPrimaryButton(
              label: l10n.commonDone,
              isExpanded: true,
              onPressed: notifier.finishCompletion,
            ),
          ),
        ),
        VocaboTextButton(
          label: l10n.trayFlashcardsOpen,
          onPressed: () {
            notifier.finishCompletion();
            onOpenFlashcards();
          },
        ),
      ],
    );
  }
}
