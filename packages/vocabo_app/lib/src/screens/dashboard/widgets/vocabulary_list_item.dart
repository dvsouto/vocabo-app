import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';

class VocabularyListItem extends ConsumerWidget {
  const VocabularyListItem({super.key, required this.userVocabulary});

  final UserVocabulary userVocabulary;

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return l10n.libraryAddedToday;
    if (diff.inDays == 1) return l10n.libraryAddedYesterday;
    if (diff.inDays < 7) return l10n.libraryAddedDaysAgo(diff.inDays);
    return DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = userVocabulary.vocabulary!;
    final l10n = context.l10n;
    final showTranslations = ref.watch(showTranslationsProvider);
    final contentHash = vocabulary.contentHash ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(selectedWordProvider.notifier).state = userVocabulary;
          ref.read(showWordDetailModalProvider.notifier).state = true;
        },
        mouseCursor: SystemMouseCursors.click,
        borderRadius: VocaboRadius.lg,
        child: Container(
          padding: const EdgeInsets.all(VocaboSpacing.lg),
          decoration: BoxDecoration(
            color: VocaboColors.surfaceContainerLowest,
            borderRadius: VocaboRadius.lg,
            boxShadow: [VocaboShadows.whisper],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audio button
              PronunciationButton(
                vocabularyId: vocabulary.id,
                type: userVocabulary.vocabularyType.value,
                contentHash: contentHash,
                size: 44,
                iconSize: 20,
              ),
              const SizedBox(width: VocaboSpacing.md),

              // Word info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(vocabulary.term, style: VocaboTypography.titleLg),
                        const SizedBox(width: 8),
                        Text(
                          wordTypeLabel(
                            l10n,
                            vocabulary.wordType,
                          ).toUpperCase(),
                          style: VocaboTypography.labelSm.copyWith(
                            color: VocaboColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VocaboSpacing.xs),
                    if (vocabulary.meaning != null && showTranslations)
                      Text(
                        vocabulary.meaning!,
                        style: VocaboTypography.bodyMd.copyWith(
                          color: VocaboColors.neutral,
                        ),
                      )
                    else if (vocabulary.meaning != null)
                      Text(
                        '••••••••••',
                        style: VocaboTypography.bodyMd.copyWith(
                          color: VocaboColors.neutral300,
                          letterSpacing: 2,
                        ),
                      ),
                    if (vocabulary.usageExamples?.sourceLang.isNotEmpty ??
                        false) ...[
                      const SizedBox(height: VocaboSpacing.xs),
                      Text(
                        vocabulary.usageExamples!.sourceLang.first,
                        style: VocaboTypography.bodySm.copyWith(
                          fontStyle: FontStyle.italic,
                          color: VocaboColors.neutral,
                        ),
                      ),
                    ],
                    const SizedBox(height: VocaboSpacing.sm),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        VocaboTagChip(
                          label:
                              userVocabulary.vocabularyType ==
                                  VocabularyType.custom
                              ? l10n.librarySourceCustom
                              : l10n.librarySourceLibrary,
                          variant:
                              userVocabulary.vocabularyType ==
                                  VocabularyType.custom
                              ? TagChipVariant.learning
                              : TagChipVariant.outlined,
                        ),
                        LocalizedMemoryStrengthDots(
                          strength:
                              userVocabulary.flashcard?.strength ??
                              MemoryStrength.of(stageIndex: 0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Date added
              Text(
                _formatDate(context, userVocabulary.createdAt),
                style: VocaboTypography.bodySm.copyWith(
                  color: VocaboColors.neutral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
