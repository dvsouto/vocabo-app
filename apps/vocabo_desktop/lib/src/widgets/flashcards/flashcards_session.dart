import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/flashcard_providers.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcard_archive_dialog.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcard_card.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcard_evaluation_bar.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcard_progress.dart';

const _contentWidth = 560.0;

class FlashcardsSession extends ConsumerStatefulWidget {
  const FlashcardsSession({super.key});

  @override
  ConsumerState<FlashcardsSession> createState() => _FlashcardsSessionState();
}

class _FlashcardsSessionState extends ConsumerState<FlashcardsSession> {
  final _focusNode = FocusNode(debugLabel: 'flashcards-session');

  @override
  void initState() {
    super.initState();
    // The home screen keeps focus while it animates out, which would make
    // `autofocus` a no-op and disable the shortcuts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  static final _evaluationKeys = <LogicalKeyboardKey, FlashcardEvaluation>{
    LogicalKeyboardKey.digit1: FlashcardEvaluation.hard,
    LogicalKeyboardKey.numpad1: FlashcardEvaluation.hard,
    LogicalKeyboardKey.digit2: FlashcardEvaluation.medium,
    LogicalKeyboardKey.numpad2: FlashcardEvaluation.medium,
    LogicalKeyboardKey.digit3: FlashcardEvaluation.easy,
    LogicalKeyboardKey.numpad3: FlashcardEvaluation.easy,
  };

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final notifier = ref.read(flashcardSessionProvider.notifier);
    final state = ref.read(flashcardSessionProvider);
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      notifier.leaveSession();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      if (!state.isFlipped) notifier.flip();
      return KeyEventResult.handled;
    }

    final evaluation = _evaluationKeys[key];
    if (evaluation != null && state.isFlipped) {
      notifier.evaluate(evaluation);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _archiveCurrent(FlashcardSessionCard card) async {
    final confirmed = await confirmArchiveFlashcard(
      context,
      hasHistory: card.flashcard.hasHistory,
    );
    if (!confirmed || !mounted) return;
    await ref.read(flashcardSessionProvider.notifier).archiveCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardSessionProvider);
    final notifier = ref.read(flashcardSessionProvider.notifier);
    final card = state.currentCard;
    final stages =
        ref.watch(flashcardConfigProvider).valueOrNull?.stages ??
        FlashcardConfig.fallback.stages;

    if (card == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final interactive = !state.isSubmitting;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back to flashcards (Esc)',
                icon: const Icon(Icons.arrow_back, size: 20),
                color: VocaboColors.neutral,
                onPressed: notifier.leaveSession,
                style: const ButtonStyle(
                  mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
                ),
              ),
              const SizedBox(width: VocaboSpacing.xs),
              Text('Review session', style: VocaboTypography.titleLg),
            ],
          ),
          const SizedBox(height: VocaboSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentWidth),
            child: FlashcardProgress(
              current: state.evaluatedCount,
              total: state.totalCards,
            ),
          ),
          const SizedBox(height: VocaboSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              state.isFlipped
                  ? 'How clear was it?'
                  : card.flashcard.direction == FlashcardDirection.reverse
                  ? 'Which English word means this?'
                  : 'What does it mean to you?',
              key: ValueKey(state.isFlipped),
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: VocaboSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentWidth),
                  child: FlashcardCard(
                    key: ValueKey(card.id),
                    card: card,
                    isFlipped: state.isFlipped,
                    isExpanded: state.isExpanded,
                    enabled: interactive,
                    onFlip: notifier.flip,
                    onToggleMeaning: notifier.toggleMeaning,
                    onSetAside: () => _archiveCurrent(card),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: VocaboSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentWidth),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: state.isFlipped
                  ? FlashcardEvaluationBar(
                      key: ValueKey('evaluate-${card.id}'),
                      selected: state.selectedEvaluation,
                      enabled: interactive,
                      onEvaluate: notifier.evaluate,
                      stageIndex: card.flashcard.currentStageIndex,
                      stages: stages,
                    )
                  : VocaboPrimaryButton(
                      key: ValueKey('continue-${card.id}'),
                      label: 'Continue',
                      trailing: const VocaboKeyCap(
                        'Space',
                        color: VocaboColors.onPrimary,
                      ),
                      isExpanded: true,
                      onPressed: interactive ? notifier.flip : null,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
