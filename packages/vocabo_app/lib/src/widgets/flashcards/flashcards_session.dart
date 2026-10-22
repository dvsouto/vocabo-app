import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

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

    final provider = flashcardDeckSessionProvider(
      ref.read(currentFlashcardDeckProvider),
    );
    final notifier = ref.read(provider.notifier);
    final state = ref.read(provider);
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
    await ref
        .read(
          flashcardDeckSessionProvider(
            ref.read(currentFlashcardDeckProvider),
          ).notifier,
        )
        .archiveCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final provider = flashcardDeckSessionProvider(
      ref.watch(currentFlashcardDeckProvider),
    );
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final l10n = context.l10n;
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Short windows get the compact card so the answer buttons and
          // the card actions stay visible without scrolling.
          final compact = constraints.maxHeight < 600;
          final gap = compact ? VocaboSpacing.sm : VocaboSpacing.lg;
          return Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.flashcardsBackToFlashcardsTooltip(
                      l10n.flashcardsKeyEsc,
                    ),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    color: VocaboColors.neutral,
                    onPressed: notifier.leaveSession,
                    style: const ButtonStyle(
                      mouseCursor: WidgetStatePropertyAll(
                        SystemMouseCursors.click,
                      ),
                    ),
                  ),
                  const SizedBox(width: VocaboSpacing.xs),
                  Text(
                    l10n.flashcardsReviewSession,
                    style: VocaboTypography.titleLg,
                  ),
                ],
              ),
              SizedBox(height: gap),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentWidth),
                child: FlashcardProgress(
                  current: state.evaluatedCount,
                  total: state.totalCards,
                ),
              ),
              SizedBox(height: gap),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  state.isFlipped
                      ? l10n.flashcardsHowClearPrompt
                      : card.flashcard.direction == FlashcardDirection.reverse
                      ? l10n.flashcardsReversePrompt
                      : l10n.flashcardsForwardPrompt,
                  key: ValueKey(state.isFlipped),
                  style: VocaboTypography.bodyMd.copyWith(
                    color: VocaboColors.neutral,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: gap),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _contentWidth,
                      ),
                      child: FlashcardCard(
                        key: ValueKey(card.id),
                        card: card,
                        compact: compact,
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
              SizedBox(height: gap),
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
                          compact: compact,
                        )
                      : VocaboPrimaryButton(
                          key: ValueKey('continue-${card.id}'),
                          label: l10n.commonContinue,
                          trailing: context.isCompact
                              ? null
                              : VocaboKeyCap(
                                  l10n.flashcardsKeySpace,
                                  color: VocaboColors.onPrimary,
                                ),
                          isExpanded: true,
                          onPressed: interactive ? notifier.flip : null,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
