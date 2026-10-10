import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';

const _flipDuration = Duration(milliseconds: 375);
const _flipCurve = Cubic(0.3, 0.3, 0.24, 1);
const _maxUsageExamples = 2;
const _cardMinHeight = 360.0;

class FlashcardCard extends ConsumerStatefulWidget {
  const FlashcardCard({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.isExpanded,
    required this.onFlip,
    required this.onToggleMeaning,
    required this.onArchive,
    this.enabled = true,
  });

  final FlashcardSessionCard card;
  final bool isFlipped;
  final bool isExpanded;
  final VoidCallback onFlip;
  final VoidCallback onToggleMeaning;
  final VoidCallback onArchive;
  final bool enabled;

  @override
  ConsumerState<FlashcardCard> createState() => _FlashcardCardState();
}

class _FlashcardCardState extends ConsumerState<FlashcardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _flipDuration,
    value: widget.isFlipped ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant FlashcardCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFlipped != widget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Vocabulary? get _vocabulary => widget.card.flashcard.vocabulary;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _flipCurve.transform(_controller.value) * math.pi;
        final showBack = angle > math.pi / 2;

        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(angle);

        Widget face = showBack ? _buildBack(context) : _buildFront(context);

        if (showBack) {
          face = Transform(
            transform: Matrix4.identity()..rotateY(math.pi),
            alignment: Alignment.center,
            child: face,
          );
        }

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: face,
        );
      },
    );
  }

  Widget _buildSurface({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: VocaboRadius.xl,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: Material(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: VocaboRadius.xl,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.enabled ? widget.onFlip : null,
          mouseCursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          hoverColor: Colors.transparent,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(minHeight: _cardMinHeight),
              padding: const EdgeInsets.all(VocaboSpacing.lg),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    final flashcard = widget.card.flashcard;

    return Row(
      children: [
        VocaboTagChip(
          label: flashcard.stageLabel,
          variant: flashcard.hasRegressed
              ? TagChipVariant.learning
              : TagChipVariant.outlined,
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Archive from reviews',
          icon: const Icon(Icons.archive_outlined, size: 20),
          color: VocaboColors.neutral,
          onPressed: widget.enabled ? widget.onArchive : null,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          style: const ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow({required bool meaningActive}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _AudioButton(
          vocabulary: _vocabulary,
          vocabularyType: widget.card.flashcard.vocabularyType,
        ),
        const SizedBox(width: VocaboSpacing.lg),
        _RoundIconButton(
          tooltip: meaningActive ? 'Hide meaning' : 'Show meaning',
          icon: Icons.translate,
          isActive: meaningActive,
          onTap: widget.enabled ? widget.onToggleMeaning : null,
        ),
      ],
    );
  }

  Widget _buildFront(BuildContext context) {
    final vocabulary = _vocabulary;
    final pronunciation = vocabulary?.pronunciation;

    return _buildSurface(
      child: Column(
        children: [
          _buildTopRow(),
          const SizedBox(height: VocaboSpacing.xl),
          Text(
            vocabulary?.term ?? '—',
            textAlign: TextAlign.center,
            style: VocaboTypography.displayMd,
          ),
          if (pronunciation != null && pronunciation.isNotEmpty) ...[
            const SizedBox(height: VocaboSpacing.sm),
            Text(
              pronunciation,
              textAlign: TextAlign.center,
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
          ],
          if (vocabulary != null) ...[
            const SizedBox(height: VocaboSpacing.sm),
            Text(
              vocabulary.wordType.value.toUpperCase(),
              style: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.primary,
              ),
            ),
          ],
          const SizedBox(height: VocaboSpacing.xxl),
          _buildBottomRow(meaningActive: false),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context) {
    final vocabulary = _vocabulary;
    final translation = vocabulary?.translation;
    final hasTranslation = translation != null && translation.isNotEmpty;
    final meaning = vocabulary?.meaning;
    final hasMeaning = meaning != null && meaning.isNotEmpty;
    final examples = (vocabulary?.usageExamples?.sourceLang ?? const [])
        .take(_maxUsageExamples)
        .toList();

    return _buildSurface(
      child: Column(
        children: [
          _buildTopRow(),
          const SizedBox(height: VocaboSpacing.xl),
          Text(
            vocabulary?.term ?? '—',
            textAlign: TextAlign.center,
            style: VocaboTypography.titleLg.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.md),
          _SectionLabel('TRANSLATION'),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            hasTranslation ? translation : '—',
            textAlign: TextAlign.center,
            style: VocaboTypography.headlineSm.copyWith(
              color: hasTranslation
                  ? VocaboColors.onSurface
                  : VocaboColors.neutral,
            ),
          ),
          if (widget.isExpanded) ...[
            if (hasMeaning) ...[
              const SizedBox(height: VocaboSpacing.lg),
              _SectionLabel('MEANING'),
              const SizedBox(height: VocaboSpacing.xs),
              Text(
                meaning,
                textAlign: TextAlign.center,
                style: VocaboTypography.bodyMd,
              ),
            ],
            if (examples.isNotEmpty) ...[
              const SizedBox(height: VocaboSpacing.lg),
              _SectionLabel('EXAMPLES'),
              const SizedBox(height: VocaboSpacing.sm),
              ...examples.map(
                (example) => Padding(
                  padding: const EdgeInsets.only(bottom: VocaboSpacing.sm),
                  child: HighlightedExampleText(
                    example: example,
                    term: vocabulary?.term ?? '',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: VocaboSpacing.xxl),
          _buildBottomRow(meaningActive: widget.isExpanded),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: VocaboTypography.labelSm.copyWith(
        color: VocaboColors.neutral,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.tooltip,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          mouseCursor: onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? VocaboColors.primary
                  : VocaboColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? VocaboColors.onPrimary : VocaboColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioButton extends ConsumerWidget {
  const _AudioButton({required this.vocabulary, required this.vocabularyType});

  final Vocabulary? vocabulary;
  final VocabularyType vocabularyType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerStateProvider);
    final contentHash = vocabulary?.contentHash ?? '';
    final canPlay = vocabulary != null && contentHash.isNotEmpty;
    final isThisPlaying =
        canPlay && audioState.currentPlayingHash == contentHash;
    final isBusy =
        audioState.status == AudioPlayerStatus.loading ||
        audioState.status == AudioPlayerStatus.playing;

    return Tooltip(
      message: 'Listen',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          mouseCursor: canPlay
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onTap: !canPlay
              ? null
              : () {
                  final player = ref.read(audioPlayerServiceProvider);
                  if (isThisPlaying && isBusy) {
                    player.stop();
                  } else if (!isBusy) {
                    player.play(
                      vocabularyId: vocabulary!.id,
                      type: vocabularyType.value,
                      contentHash: contentHash,
                    );
                  }
                },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: canPlay
                  ? VocaboColors.primary
                  : VocaboColors.primary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child:
                isThisPlaying && audioState.status == AudioPlayerStatus.loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VocaboColors.onPrimary,
                    ),
                  )
                : Icon(
                    isThisPlaying &&
                            audioState.status == AudioPlayerStatus.playing
                        ? Icons.stop
                        : Icons.volume_up,
                    color: VocaboColors.onPrimary,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
