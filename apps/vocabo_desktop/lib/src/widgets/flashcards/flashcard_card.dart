import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/word_type_labels.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';

const _flipDuration = Duration(milliseconds: 375);
const _flipCurve = Cubic(0.3, 0.3, 0.24, 1);

class FlashcardCard extends ConsumerStatefulWidget {
  const FlashcardCard({
    super.key,
    required this.card,
    required this.isFlipped,
    required this.isExpanded,
    required this.onFlip,
    required this.onToggleMeaning,
    this.onSetAside,
    this.enabled = true,
    this.compact = false,
  });

  final FlashcardSessionCard card;
  final bool isFlipped;
  final bool isExpanded;
  final VoidCallback onFlip;
  final VoidCallback onToggleMeaning;

  /// Removes the word from reviews. Hidden when null.
  final VoidCallback? onSetAside;
  final bool enabled;

  /// Smaller layout used by the menu bar panel.
  final bool compact;

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

  Flashcard get _flashcard => widget.card.flashcard;
  Vocabulary? get _vocabulary => _flashcard.vocabulary;
  bool get _isReverse => _flashcard.direction == FlashcardDirection.reverse;
  bool get _compact => widget.compact;
  int get _maxExamples => _compact ? 1 : 2;

  /// What the reverse front asks about: the translation, or the meaning
  /// when the term has no literal translation.
  String get _reversePrompt {
    final translation = _vocabulary?.translation;
    if (translation != null && translation.isNotEmpty) return translation;
    return _vocabulary?.meaning ?? '—';
  }

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

        Widget face = showBack ? _buildBack() : _buildFront();

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
        borderRadius: _compact ? VocaboRadius.lg : VocaboRadius.xl,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: Material(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: _compact ? VocaboRadius.lg : VocaboRadius.xl,
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
              constraints: BoxConstraints(minHeight: _compact ? 210 : 360),
              padding: EdgeInsets.all(
                _compact ? VocaboSpacing.md : VocaboSpacing.lg,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    final l10n = context.l10n;
    final strength = MemoryStrength.of(
      stageIndex: _flashcard.currentStageIndex,
      status: _flashcard.status,
    );
    final strengthName = l10n.memoryStrengthName(strength);

    return Row(
      children: [
        MemoryStrengthDots(
          strength: strength,
          label: strengthName,
          semanticsLabel: l10n.flashcardsStrengthSemantics(
            strengthName,
            strength.level,
            MemoryStrength.totalLevels,
          ),
          dotSize: _compact ? 5 : 6,
        ),
        const Spacer(),
        if (widget.onSetAside != null)
          IconButton(
            tooltip: l10n.flashcardsSetAside,
            icon: const Icon(Icons.archive_outlined, size: 20),
            color: VocaboColors.neutral,
            onPressed: widget.enabled ? widget.onSetAside : null,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            style: const ButtonStyle(
              mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
            ),
          )
        else
          const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildBottomRow({required bool meaningActive, bool showAudio = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showAudio) ...[
          _AudioButton(
            vocabulary: _vocabulary,
            vocabularyType: _flashcard.vocabularyType,
            size: _compact ? 36 : 44,
          ),
          SizedBox(width: _compact ? VocaboSpacing.md : VocaboSpacing.lg),
        ],
        _RoundIconButton(
          tooltip: meaningActive
              ? context.l10n.flashcardsHideMeaning
              : context.l10n.flashcardsShowMeaning,
          icon: Icons.translate,
          isActive: meaningActive,
          size: _compact ? 36 : 44,
          onTap: widget.enabled ? widget.onToggleMeaning : null,
        ),
      ],
    );
  }

  TextStyle get _termStyle =>
      _compact ? VocaboTypography.headlineSm : VocaboTypography.displayMd;

  Widget _buildFront() {
    return _buildSurface(
      child: Column(
        children: [
          _buildTopRow(),
          SizedBox(height: _compact ? VocaboSpacing.md : VocaboSpacing.xl),
          if (_isReverse) ..._buildReversePrompt() else ..._buildTermHeader(),
          SizedBox(height: _compact ? VocaboSpacing.lg : VocaboSpacing.xxl),
          _buildBottomRow(meaningActive: false, showAudio: !_isReverse),
        ],
      ),
    );
  }

  List<Widget> _buildTermHeader() {
    final vocabulary = _vocabulary;
    final pronunciation = vocabulary?.pronunciation;

    return [
      Text(
        vocabulary?.term ?? '—',
        textAlign: TextAlign.center,
        style: _termStyle,
      ),
      if (pronunciation != null && pronunciation.isNotEmpty) ...[
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          pronunciation,
          textAlign: TextAlign.center,
          style: VocaboTypography.bodyMd.copyWith(color: VocaboColors.neutral),
        ),
      ],
      if (vocabulary != null) ...[
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          wordTypeLabel(context.l10n, vocabulary.wordType).toUpperCase(),
          style: VocaboTypography.labelSm.copyWith(color: VocaboColors.primary),
        ),
      ],
    ];
  }

  List<Widget> _buildReversePrompt() {
    return [
      _SectionLabel(context.l10n.flashcardsWhichEnglishWordLabel),
      const SizedBox(height: VocaboSpacing.sm),
      Text(
        _reversePrompt,
        textAlign: TextAlign.center,
        style: _compact
            ? VocaboTypography.titleLg
            : VocaboTypography.headlineSm,
      ),
      if (_vocabulary != null) ...[
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          wordTypeLabel(context.l10n, _vocabulary!.wordType).toUpperCase(),
          style: VocaboTypography.labelSm.copyWith(color: VocaboColors.primary),
        ),
      ],
    ];
  }

  Widget _buildBack() {
    final vocabulary = _vocabulary;
    final translation = vocabulary?.translation;
    final hasTranslation = translation != null && translation.isNotEmpty;
    final meaning = vocabulary?.meaning;
    final hasMeaning = meaning != null && meaning.isNotEmpty;
    final examples = (vocabulary?.usageExamples?.sourceLang ?? const [])
        .take(_maxExamples)
        .toList();

    return _buildSurface(
      child: Column(
        children: [
          _buildTopRow(),
          SizedBox(height: _compact ? VocaboSpacing.md : VocaboSpacing.xl),
          if (_isReverse) ...[
            ..._buildTermHeader(),
            const SizedBox(height: VocaboSpacing.md),
            Text(
              _reversePrompt,
              textAlign: TextAlign.center,
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
          ] else ...[
            Text(
              vocabulary?.term ?? '—',
              textAlign: TextAlign.center,
              style: VocaboTypography.titleLg.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            const SizedBox(height: VocaboSpacing.md),
            _SectionLabel(context.l10n.flashcardsTranslationLabel),
            const SizedBox(height: VocaboSpacing.xs),
            Text(
              hasTranslation ? translation : '—',
              textAlign: TextAlign.center,
              style:
                  (_compact
                          ? VocaboTypography.titleLg
                          : VocaboTypography.headlineSm)
                      .copyWith(
                        color: hasTranslation
                            ? VocaboColors.onSurface
                            : VocaboColors.neutral,
                      ),
            ),
          ],
          if (widget.isExpanded) ...[
            if (hasMeaning && !(_isReverse && !hasTranslation)) ...[
              const SizedBox(height: VocaboSpacing.lg),
              _SectionLabel(context.l10n.flashcardsMeaningLabel),
              const SizedBox(height: VocaboSpacing.xs),
              Text(
                meaning,
                textAlign: TextAlign.center,
                style: VocaboTypography.bodyMd,
              ),
            ],
            if (examples.isNotEmpty) ...[
              const SizedBox(height: VocaboSpacing.lg),
              _SectionLabel(context.l10n.flashcardsExamplesLabel),
              const SizedBox(height: VocaboSpacing.sm),
              ...examples.map(
                (example) => Padding(
                  padding: const EdgeInsets.only(bottom: VocaboSpacing.sm),
                  child: HighlightedExampleText(
                    example: example,
                    term: vocabulary?.term ?? '',
                    textAlign: TextAlign.center,
                    fontSize: _compact ? 13 : 14,
                  ),
                ),
              ),
            ],
          ],
          SizedBox(height: _compact ? VocaboSpacing.lg : VocaboSpacing.xxl),
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
      textAlign: TextAlign.center,
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
    required this.size,
  });

  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;
  final double size;

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
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isActive
                  ? VocaboColors.primary
                  : VocaboColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: size * 0.45,
              color: isActive ? VocaboColors.onPrimary : VocaboColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioButton extends ConsumerWidget {
  const _AudioButton({
    required this.vocabulary,
    required this.vocabularyType,
    required this.size,
  });

  final Vocabulary? vocabulary;
  final VocabularyType vocabularyType;
  final double size;

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
      message: context.l10n.flashcardsListen,
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
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: canPlay
                  ? VocaboColors.primary
                  : VocaboColors.primary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child:
                isThisPlaying && audioState.status == AudioPlayerStatus.loading
                ? Padding(
                    padding: EdgeInsets.all(size * 0.27),
                    child: const CircularProgressIndicator(
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
                    size: size * 0.45,
                  ),
          ),
        ),
      ),
    );
  }
}
