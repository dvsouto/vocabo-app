import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/widgets/audio/pronunciation_button.dart';

class TrayWordItem extends ConsumerWidget {
  const TrayWordItem({super.key, required this.userVocabulary});

  final UserVocabulary userVocabulary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = userVocabulary.vocabulary!;
    final contentHash = vocabulary.contentHash ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VocaboSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                vocabulary.term,
                style: VocaboTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              PronunciationButton(
                vocabularyId: vocabulary.id,
                type: userVocabulary.vocabularyType.value,
                contentHash: contentHash,
                size: 28,
                iconSize: 14,
                tonal: true,
              ),
            ],
          ),
          if (vocabulary.meaning != null) ...[
            const SizedBox(height: 4),
            Text(
              vocabulary.meaning!,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
