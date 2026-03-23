import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class VocabularyListItem extends StatelessWidget {
  const VocabularyListItem({
    super.key,
    required this.vocabulary,
    required this.tags,
    required this.lastPracticed,
  });

  final Vocabulary vocabulary;
  final List<({String label, String variant})> tags;
  final String lastPracticed;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          GestureDetector(
            onTap: () {
              // TODO: play TTS pronunciation
              debugPrint('Play audio: ${vocabulary.term}');
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: VocaboColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volume_up,
                color: VocaboColors.onPrimary,
                size: 20,
              ),
            ),
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
                      vocabulary.wordType.value.toUpperCase(),
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VocaboSpacing.xs),
                if (vocabulary.meaning != null)
                  Text(
                    vocabulary.meaning!,
                    style: VocaboTypography.bodyMd.copyWith(
                      color: VocaboColors.neutral,
                    ),
                  ),
                if (vocabulary.usageExamples?.sourceLang.isNotEmpty ?? false)
                  ...[
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
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.map((tag) {
                    return VocaboTagChip(
                      label: tag.label,
                      variant: switch (tag.variant) {
                        'mastered' => TagChipVariant.mastered,
                        'learning' => TagChipVariant.learning,
                        _ => TagChipVariant.outlined,
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Last practiced
          Text(
            lastPracticed,
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
        ],
      ),
    );
  }
}
