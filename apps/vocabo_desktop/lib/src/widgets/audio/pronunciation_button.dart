import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';

/// The play button used wherever a pronunciation can be heard.
///
/// A click plays the word; clicking again while it plays or right after
/// replays it at half speed. A right click or long press goes straight to
/// the slow replay, and [showSlowButton] adds a visible "0.5×" button for
/// places with room for it.
class PronunciationButton extends ConsumerWidget {
  const PronunciationButton({
    super.key,
    required this.vocabularyId,
    required this.type,
    required this.contentHash,
    this.size = 32,
    this.iconSize,
    this.tonal = false,
    this.showSlowButton = false,
  });

  final String? vocabularyId;
  final String type;
  final String? contentHash;
  final double size;
  final double? iconSize;

  /// A light background with a colored icon, for dense lists.
  final bool tonal;
  final bool showSlowButton;

  bool get _canPlay =>
      vocabularyId != null && (contentHash?.isNotEmpty ?? false);

  void _toggle(WidgetRef ref, {bool slow = false}) {
    ref
        .read(audioPlayerServiceProvider)
        .toggle(
          vocabularyId: vocabularyId!,
          type: type,
          contentHash: contentHash!,
          slow: slow,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerStateProvider);
    final canPlay = _canPlay;
    final isThis = canPlay && audioState.currentPlayingHash == contentHash;
    final isLoading = isThis && audioState.status == AudioPlayerStatus.loading;
    final isPlaying = isThis && audioState.status == AudioPlayerStatus.playing;
    final isSlow = (isLoading || isPlaying) && audioState.isSlow;

    final background = tonal
        ? VocaboColors.surfaceContainerLow
        : VocaboColors.primary;
    final foreground = tonal ? VocaboColors.primary : VocaboColors.onPrimary;

    final play = Tooltip(
      message: context.l10n.audioPlayHint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          mouseCursor: canPlay
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onTap: canPlay ? () => _toggle(ref) : null,
          onSecondaryTap: canPlay ? () => _toggle(ref, slow: true) : null,
          onLongPress: canPlay ? () => _toggle(ref, slow: true) : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: canPlay
                      ? background
                      : background.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? Padding(
                        padding: EdgeInsets.all(size * 0.27),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.stop : Icons.volume_up,
                        color: canPlay
                            ? foreground
                            : foreground.withValues(alpha: 0.5),
                        size: iconSize ?? size * 0.45,
                      ),
              ),
              if (isSlow && !showSlowButton)
                const Positioned(right: -6, bottom: -4, child: _SpeedTag()),
            ],
          ),
        ),
      ),
    );

    if (!showSlowButton) return play;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        play,
        const SizedBox(width: VocaboSpacing.xs),
        Tooltip(
          message: context.l10n.audioPlaySlow,
          child: Material(
            color: isSlow ? VocaboColors.primary : VocaboColors.primary50,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              mouseCursor: canPlay
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onTap: canPlay ? () => _toggle(ref, slow: true) : null,
              child: Container(
                height: size * 0.75,
                constraints: BoxConstraints(minWidth: size),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: Text(
                  '0.5×',
                  style: VocaboTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSlow
                        ? VocaboColors.onPrimary
                        : canPlay
                        ? VocaboColors.primary
                        : VocaboColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Marks a play button while the slow replay is on.
class _SpeedTag extends StatelessWidget {
  const _SpeedTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: VocaboColors.onSurface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '0.5×',
        style: VocaboTypography.labelSm.copyWith(
          color: VocaboColors.surfaceContainerLowest,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
