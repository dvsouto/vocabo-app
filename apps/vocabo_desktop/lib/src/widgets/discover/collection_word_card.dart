import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/discover_providers.dart';
import 'package:vocabo_desktop/src/widgets/discover/word_audio_button.dart';

/// A collection word. The translation is only requested once the card is
/// clicked, then cached.
class CollectionWordCard extends ConsumerStatefulWidget {
  const CollectionWordCard({super.key, required this.item});

  final CollectionItem item;

  @override
  ConsumerState<CollectionWordCard> createState() => _CollectionWordCardState();
}

class _CollectionWordCardState extends ConsumerState<CollectionWordCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _revealed
            ? VocaboColors.surfaceContainerLowest
            : VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.md,
        boxShadow: _revealed ? [VocaboShadows.whisper] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => setState(() => _revealed = !_revealed),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: VocaboRadius.md,
          child: Padding(
            padding: const EdgeInsets.all(VocaboSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.term,
                  style: VocaboTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.topLeft,
                  child: _revealed
                      ? Padding(
                          padding: const EdgeInsets.only(top: VocaboSpacing.sm),
                          child: SuggestedTranslation(
                            term: item.term,
                            cached: item.vocabulary,
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The translation of a suggested word, requested when first shown.
class SuggestedTranslation extends ConsumerWidget {
  const SuggestedTranslation({super.key, required this.term, this.cached});

  final String term;
  final Vocabulary? cached;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cached = this.cached;
    final vocabulary = cached != null
        ? AsyncValue.data(cached)
        : ref.watch(suggestedVocabularyProvider(term));

    return vocabulary.when(
      loading: () => Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: VocaboSpacing.sm),
          Text(
            l10n.flashcardsTranslating,
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
        ],
      ),
      error: (_, _) => Row(
        children: [
          Expanded(
            child: Text(
              l10n.suggestedTranslateFailed,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.commonRetry,
            icon: const Icon(Icons.refresh, size: 18),
            color: VocaboColors.neutral,
            onPressed: () => ref.invalidate(suggestedVocabularyProvider(term)),
          ),
        ],
      ),
      data: (vocabulary) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              vocabulary.translation ?? vocabulary.meaning ?? '—',
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral700,
              ),
            ),
          ),
          const SizedBox(width: VocaboSpacing.sm),
          WordAudioButton(vocabulary: vocabulary, size: 28),
        ],
      ),
    );
  }
}
