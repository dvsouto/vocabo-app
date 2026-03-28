import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';

class TrayWordItem extends ConsumerWidget {
  const TrayWordItem({super.key, required this.userVocabulary});

  final UserVocabulary userVocabulary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = userVocabulary.vocabulary!;
    final audioState = ref.watch(audioPlayerStateProvider);
    final contentHash = vocabulary.contentHash ?? '';
    final isThisPlaying = audioState.currentPlayingHash == contentHash;
    final isBusy = audioState.status == AudioPlayerStatus.loading ||
        audioState.status == AudioPlayerStatus.playing;

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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: contentHash.isEmpty
                      ? null
                      : () {
                          final player =
                              ref.read(audioPlayerServiceProvider);
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
                  mouseCursor: contentHash.isEmpty
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: contentHash.isEmpty
                          ? VocaboColors.surfaceContainerLow
                              .withValues(alpha: 0.5)
                          : VocaboColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: isThisPlaying &&
                            audioState.status == AudioPlayerStatus.loading
                        ? const Padding(
                            padding: EdgeInsets.all(7),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: VocaboColors.primary,
                            ),
                          )
                        : Icon(
                            isThisPlaying &&
                                    audioState.status ==
                                        AudioPlayerStatus.playing
                                ? Icons.stop
                                : Icons.volume_up,
                            size: 14,
                            color: contentHash.isEmpty
                                ? VocaboColors.primary
                                    .withValues(alpha: 0.5)
                                : VocaboColors.primary,
                          ),
                  ),
                ),
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
