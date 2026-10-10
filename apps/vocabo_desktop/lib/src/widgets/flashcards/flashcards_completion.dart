import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/flashcard_providers.dart';

const _autoReturnDelay = Duration(seconds: 4);

class FlashcardsCompletion extends ConsumerStatefulWidget {
  const FlashcardsCompletion({super.key});

  @override
  ConsumerState<FlashcardsCompletion> createState() =>
      _FlashcardsCompletionState();
}

class _FlashcardsCompletionState extends ConsumerState<FlashcardsCompletion> {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 3),
  );
  Timer? _autoReturn;

  @override
  void initState() {
    super.initState();
    _confetti.play();
    _autoReturn = Timer(_autoReturnDelay, () {
      if (mounted) {
        ref.read(flashcardSessionProvider.notifier).finishCompletion();
      }
    });
  }

  @override
  void dispose() {
    _autoReturn?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashcardSessionProvider);
    final notifier = ref.read(flashcardSessionProvider.notifier);
    final reviewed = state.evaluatedCount;

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 24,
            emissionFrequency: 0.05,
            gravity: 0.2,
            maxBlastForce: 18,
            minBlastForce: 6,
            colors: const [
              VocaboColors.primary,
              VocaboColors.secondary,
              VocaboColors.tertiary,
              VocaboColors.tertiaryFixed,
              VocaboColors.primary200,
            ],
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: VocaboColors.tertiary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: VocaboColors.tertiary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: VocaboSpacing.lg),
                Text('Review complete!', style: VocaboTypography.headlineSm),
                const SizedBox(height: VocaboSpacing.xs),
                Text(
                  reviewed == 1
                      ? '1 card reviewed'
                      : '$reviewed cards reviewed',
                  style: VocaboTypography.bodyMd.copyWith(
                    color: VocaboColors.neutral,
                  ),
                ),
                const SizedBox(height: VocaboSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Count(
                      value: state.countOf(FlashcardEvaluation.hard),
                      label: "DIDN'T RECALL",
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: VocaboSpacing.xl),
                    _Count(
                      value: state.countOf(FlashcardEvaluation.medium),
                      label: 'ALMOST',
                      color: VocaboColors.onSurface,
                    ),
                    const SizedBox(width: VocaboSpacing.xl),
                    _Count(
                      value: state.countOf(FlashcardEvaluation.easy),
                      label: 'RECALLED',
                      color: const Color(0xFF1E8E3E),
                    ),
                  ],
                ),
                const SizedBox(height: VocaboSpacing.xl),
                VocaboPrimaryButton(
                  label: 'Back to flashcards',
                  onPressed: notifier.finishCompletion,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: VocaboTypography.headlineSm.copyWith(color: color),
        ),
        const SizedBox(height: VocaboSpacing.xs),
        Text(
          label,
          style: VocaboTypography.labelSm.copyWith(color: VocaboColors.neutral),
        ),
      ],
    );
  }
}
