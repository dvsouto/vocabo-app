import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/providers/word_detail_providers.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';

class WordDetailModal extends ConsumerWidget {
  const WordDetailModal({super.key, required this.userVocabulary});

  final UserVocabulary userVocabulary;

  String _formatFullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _close(WidgetRef ref) {
    ref.read(showWordDetailModalProvider.notifier).state = false;
    ref.read(selectedWordProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = userVocabulary.vocabulary!;
    final showDetail = ref.watch(showWordDetailModalProvider);
    final audioState = ref.watch(audioPlayerStateProvider);
    final contentHash = vocabulary.contentHash ?? '';
    final isThisPlaying =
        showDetail && audioState.currentPlayingHash == contentHash;
    final isBusy = audioState.status == AudioPlayerStatus.loading ||
        audioState.status == AudioPlayerStatus.playing;

    final hasTranslation =
        vocabulary.translation != null && vocabulary.translation!.isNotEmpty;
    final hasMeaning =
        vocabulary.meaning != null && vocabulary.meaning!.isNotEmpty;
    final examples = vocabulary.usageExamples?.sourceLang ?? [];

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 760,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: VocaboColors.surface,
            borderRadius: VocaboRadius.lg,
            boxShadow: [VocaboShadows.whisper],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                VocaboSpacing.xl,
                VocaboSpacing.lg,
                VocaboSpacing.xl,
                VocaboSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(ref, vocabulary),
                  const SizedBox(height: VocaboSpacing.lg),
                  _buildTermRow(
                    ref, vocabulary, contentHash,
                    isThisPlaying, isBusy, audioState,
                  ),
                  const SizedBox(height: VocaboSpacing.xl),
                  _buildTopColumns(
                    vocabulary, hasTranslation, examples,
                  ),
                  if (hasMeaning) ...[
                    const SizedBox(height: VocaboSpacing.lg),
                    _buildMeaningSection(vocabulary),
                  ],
                  const SizedBox(height: VocaboSpacing.xl),
                  _buildDateSection(),
                  const SizedBox(height: VocaboSpacing.xl),
                  _buildActions(ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, Vocabulary vocabulary) {
    return Row(
      children: [
        VocaboTagChip(
          label: vocabulary.wordType.value.toUpperCase(),
          variant: TagChipVariant.outlined,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          color: VocaboColors.neutral,
          onPressed: () => _close(ref),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: const ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
          ),
        ),
      ],
    );
  }

  Widget _buildTermRow(
    WidgetRef ref,
    Vocabulary vocabulary,
    String contentHash,
    bool isThisPlaying,
    bool isBusy,
    AudioPlayerState audioState,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            vocabulary.term,
            style: VocaboTypography.displayMd.copyWith(
              color: VocaboColors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: VocaboSpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            mouseCursor: contentHash.isEmpty
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onTap: contentHash.isEmpty
                ? null
                : () {
                    final player = ref.read(audioPlayerServiceProvider);
                    if (isThisPlaying && isBusy) {
                      player.stop();
                    } else if (!isBusy) {
                      player.play(
                        vocabularyId: vocabulary.id,
                        type: userVocabulary.vocabularyType ==
                                VocabularyType.custom
                            ? 'custom'
                            : 'system',
                        contentHash: contentHash,
                      );
                    }
                  },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: contentHash.isEmpty
                    ? VocaboColors.primary.withValues(alpha: 0.5)
                    : VocaboColors.primary,
                shape: BoxShape.circle,
              ),
              child: isThisPlaying &&
                      audioState.status == AudioPlayerStatus.loading
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
                      size: 22,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopColumns(
    Vocabulary vocabulary,
    bool hasTranslation,
    List<String> examples,
  ) {
    if (!hasTranslation && examples.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!hasTranslation && examples.isNotEmpty) {
      return _buildExamplesSection(examples, vocabulary);
    }

    if (hasTranslation && examples.isEmpty) {
      return _buildTranslationColumn(vocabulary);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildTranslationColumn(vocabulary),
        ),
        const SizedBox(width: VocaboSpacing.xxl),
        Expanded(
          flex: 3,
          child: _buildExamplesSection(examples, vocabulary),
        ),
      ],
    );
  }

  Widget _buildTranslationColumn(Vocabulary vocabulary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TRANSLATION',
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.neutral,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          vocabulary.translation!,
          style: VocaboTypography.bodyMd.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMeaningSection(Vocabulary vocabulary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEANING',
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.neutral,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          vocabulary.meaning!,
          style: VocaboTypography.bodyMd.copyWith(fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildExamplesSection(List<String> examples, Vocabulary vocabulary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXAMPLE SENTENCES',
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.neutral,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),
        ...examples.map((example) => Padding(
              padding: const EdgeInsets.only(bottom: VocaboSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 10),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: VocaboColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildHighlightedExample(
                      example,
                      vocabulary.term,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildHighlightedExample(String example, String term) {
    final quotedExample = '"$example"';
    final lowerExample = quotedExample.toLowerCase();
    final lowerTerm = term.toLowerCase();
    final index = lowerExample.indexOf(lowerTerm);

    const baseStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: VocaboColors.onSurface,
      height: 1.5,
    );

    if (index == -1) {
      return Text(quotedExample, style: baseStyle);
    }

    final before = quotedExample.substring(0, index);
    final match = quotedExample.substring(index, index + term.length);
    final after = quotedExample.substring(index + term.length);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Row(
      children: [
        _buildDateItem(
          icon: Icons.calendar_today_outlined,
          label: 'DATE ADDED',
          value: _formatFullDate(userVocabulary.createdAt),
        ),
        const Spacer(),
        _buildDateItem(
          icon: Icons.bolt_outlined,
          label: 'LAST PRACTICED',
          value: 'Not yet',
        ),
      ],
    );
  }

  Widget _buildDateItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: VocaboColors.surfaceContainerHigh,
            borderRadius: VocaboRadius.sm,
          ),
          child: Icon(icon, size: 16, color: VocaboColors.neutral),
        ),
        const SizedBox(width: VocaboSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            Text(
              value,
              style: VocaboTypography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(WidgetRef ref) {
    return Row(
      children: [
        VocaboTextButton(
          label: 'Edit Entry',
          leading: const Icon(Icons.edit_outlined),
          onPressed: () {},
        ),
        const Spacer(),
        VocaboNeutralButton(
          label: 'Archive',
          leading: const Icon(Icons.delete_outline),
          onPressed: () {},
        ),
      ],
    );
  }
}
