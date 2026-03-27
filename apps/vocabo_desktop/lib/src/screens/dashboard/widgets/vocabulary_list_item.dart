import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';

class VocabularyListItem extends ConsumerWidget {
  const VocabularyListItem({
    super.key,
    required this.userVocabulary,
  });

  final UserVocabulary userVocabulary;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = userVocabulary.vocabulary!;
    final audioState = ref.watch(audioPlayerStateProvider);
    final contentHash = vocabulary.contentHash ?? '';
    final isThisPlaying = audioState.currentPlayingHash == contentHash;
    final isBusy = audioState.status == AudioPlayerStatus.loading ||
        audioState.status == AudioPlayerStatus.playing;

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
          MouseRegion(
            cursor: contentHash.isEmpty
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: GestureDetector(
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
              width: 44,
              height: 44,
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
                      size: 20,
                    ),
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
                  children: [
                    VocaboTagChip(
                      label: userVocabulary.vocabularyType == VocabularyType.custom
                          ? 'CUSTOM'
                          : 'LIBRARY',
                      variant: userVocabulary.vocabularyType == VocabularyType.custom
                          ? TagChipVariant.learning
                          : TagChipVariant.outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date added
          Text(
            _formatDate(userVocabulary.createdAt),
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
        ],
      ),
    );
  }
}
