import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';

class WordDetailModal extends ConsumerWidget {
  const WordDetailModal({super.key, required this.userVocabulary});

  final UserVocabulary userVocabulary;

  String _formatFullDate(BuildContext context, DateTime date) =>
      DateFormat.yMMMMd(
        Localizations.localeOf(context).toString(),
      ).format(date);

  void _close(WidgetRef ref) {
    ref.read(showWordDetailModalProvider.notifier).state = false;
    ref.read(selectedWordProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = userVocabulary.vocabulary!;
    final flashcard = ref
        .watch(flashcardByVocabularyProvider(userVocabulary.id))
        .valueOrNull;
    final contentHash = vocabulary.contentHash ?? '';

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
                  _buildHeader(context, ref, vocabulary, flashcard),
                  const SizedBox(height: VocaboSpacing.lg),
                  _buildTermRow(ref, vocabulary, contentHash),
                  const SizedBox(height: VocaboSpacing.xl),
                  _buildTopColumns(
                    context,
                    vocabulary,
                    hasTranslation,
                    examples,
                  ),
                  if (hasMeaning) ...[
                    const SizedBox(height: VocaboSpacing.lg),
                    _buildMeaningSection(context, vocabulary),
                  ],
                  const SizedBox(height: VocaboSpacing.xl),
                  _buildDateSection(context, flashcard),
                  const SizedBox(height: VocaboSpacing.xl),
                  _buildActions(context, ref, flashcard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    Vocabulary vocabulary,
    Flashcard? flashcard,
  ) {
    return Row(
      children: [
        VocaboTagChip(
          label: wordTypeLabel(context.l10n, vocabulary.wordType).toUpperCase(),
          variant: TagChipVariant.outlined,
        ),
        if (flashcard != null) ...[
          const SizedBox(width: VocaboSpacing.md),
          LocalizedMemoryStrengthDots(
            strength: MemoryStrength.of(
              stageIndex: flashcard.currentStageIndex,
              status: flashcard.status,
            ),
          ),
        ],
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
        PronunciationButton(
          vocabularyId: vocabulary.id,
          type: userVocabulary.vocabularyType.value,
          contentHash: contentHash,
          size: 48,
          iconSize: 22,
          showSlowButton: true,
        ),
      ],
    );
  }

  Widget _buildTopColumns(
    BuildContext context,
    Vocabulary vocabulary,
    bool hasTranslation,
    List<String> examples,
  ) {
    if (!hasTranslation && examples.isEmpty) {
      return const SizedBox.shrink();
    }

    if (examples.isEmpty) {
      return _buildTranslationColumn(context, vocabulary, hasTranslation);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildTranslationColumn(context, vocabulary, hasTranslation),
        ),
        const SizedBox(width: VocaboSpacing.xxl),
        Expanded(
          flex: 3,
          child: _buildExamplesSection(context, examples, vocabulary),
        ),
      ],
    );
  }

  Widget _buildTranslationColumn(
    BuildContext context,
    Vocabulary vocabulary,
    bool hasTranslation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.wordTranslationLabel,
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.neutral,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          hasTranslation ? vocabulary.translation! : '—',
          style: VocaboTypography.bodyMd.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: hasTranslation ? null : VocaboColors.neutral,
          ),
        ),
      ],
    );
  }

  Widget _buildMeaningSection(BuildContext context, Vocabulary vocabulary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.wordMeaningLabel,
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

  Widget _buildExamplesSection(
    BuildContext context,
    List<String> examples,
    Vocabulary vocabulary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.wordExamplesLabel,
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.neutral,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),
        ...examples.map(
          (example) => Padding(
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
                  child: _buildHighlightedExample(example, vocabulary.term),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedExample(String example, String term) {
    final quotedExample = '"$example"';
    final lowerExample = quotedExample.toLowerCase();
    final lowerTerm = term.toLowerCase();
    final index = lowerExample.indexOf(lowerTerm);

    final baseStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: VocaboColors.onSurface,
      height: 1.5,
    );

    final boldStyle = GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
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
        children: [
          TextSpan(text: before, style: baseStyle),
          TextSpan(text: match, style: boldStyle),
          TextSpan(text: after, style: baseStyle),
        ],
      ),
    );
  }

  Widget _buildDateSection(BuildContext context, Flashcard? flashcard) {
    final l10n = context.l10n;
    final lastPracticed = flashcard?.lastEvaluatedAt;

    return Row(
      children: [
        _buildDateItem(
          icon: Icons.calendar_today_outlined,
          label: l10n.wordDateAdded,
          value: _formatFullDate(context, userVocabulary.createdAt),
        ),
        const Spacer(),
        _buildDateItem(
          icon: Icons.bolt_outlined,
          label: l10n.wordLastPracticed,
          value: lastPracticed == null
              ? l10n.wordNotPracticedYet
              : _formatFullDate(context, lastPracticed.toLocal()),
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

  Future<void> _toggleArchive(
    BuildContext context,
    WidgetRef ref,
    Flashcard flashcard,
  ) async {
    final api = ref.read(apiClientProvider);
    final l10n = context.l10n;
    final archived = flashcard.status == FlashcardStatus.archived;
    try {
      if (archived) {
        await api.flashcards.restore(flashcard.id);
      } else {
        await api.flashcards.archive(flashcard.id);
      }
      ref.invalidate(flashcardByVocabularyProvider(userVocabulary.id));
      ref.invalidate(archivedFlashcardsProvider);
      ref.invalidate(flashcardStatusProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              archived
                  ? l10n.wordFlashcardRestored
                  : l10n.wordFlashcardArchived,
            ),
          ),
        );
      }
    } catch (e, st) {
      if (upgradeReasonFor(e) case final reason?) {
        if (context.mounted) showPaywall(context, reason);
        return;
      }
      appLogger.handle(e, st, 'WordDetail toggleArchive() error');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.wordFlashcardUpdateFailed)));
      }
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final term = userVocabulary.vocabulary?.term;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          term == null
              ? l10n.wordRemoveTitleFallback
              : l10n.wordRemoveTitle(term),
        ),
        content: Text(l10n.wordRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.commonRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(userVocabularyListProvider.notifier)
          .removeVocabulary(userVocabulary.id);
      ref.invalidate(flashcardStatusProvider);
      ref.invalidate(archivedFlashcardsProvider);
      _close(ref);
    } catch (e, st) {
      appLogger.handle(e, st, 'WordDetail remove() error');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.wordRemoveFailed)));
      }
    }
  }

  Widget _buildActions(
    BuildContext context,
    WidgetRef ref,
    Flashcard? flashcard,
  ) {
    final l10n = context.l10n;
    final archived = flashcard?.status == FlashcardStatus.archived;

    return Row(
      children: [
        if (flashcard != null)
          VocaboTextButton(
            label: archived
                ? l10n.wordRestoreFlashcard
                : l10n.wordArchiveFlashcard,
            leading: Icon(
              archived ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            onPressed: () => _toggleArchive(context, ref, flashcard),
          ),
        const Spacer(),
        VocaboNeutralButton(
          label: l10n.commonRemove,
          leading: const Icon(Icons.delete_outline),
          onPressed: () => _remove(context, ref),
        ),
      ],
    );
  }
}
