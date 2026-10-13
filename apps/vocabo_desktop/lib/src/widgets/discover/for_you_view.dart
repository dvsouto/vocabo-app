import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/l10n/updated_at_label.dart';
import 'package:vocabo_desktop/src/pro/plan_providers.dart';
import 'package:vocabo_desktop/src/pro/pro_feature_gate.dart';
import 'package:vocabo_desktop/src/providers/discover_providers.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/widgets/discover/collection_word_card.dart';
import 'package:vocabo_desktop/src/widgets/discover/collections_catalog.dart';

/// The "For you" tab: words and collections picked each day (Pro).
class ForYouTab extends StatelessWidget {
  const ForYouTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ProFeatureGate(
      isIncluded: (limits) => limits.recommendations,
      icon: Icons.auto_awesome_outlined,
      title: context.l10n.forYouLockedTitle,
      body: context.l10n.forYouLockedBody,
      child: const _ForYouContent(),
    );
  }
}

class _ForYouContent extends ConsumerWidget {
  const _ForYouContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return ref
        .watch(recommendationsProvider)
        .when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: VocaboSpacing.md),
                Text(
                  l10n.forYouMaking,
                  style: VocaboTypography.bodyMd.copyWith(
                    color: VocaboColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.forYouUnavailable,
                  style: VocaboTypography.bodyMd.copyWith(
                    color: VocaboColors.neutral,
                  ),
                ),
                const SizedBox(height: VocaboSpacing.sm),
                VocaboTextButton(
                  label: l10n.commonTryAgain,
                  onPressed: () => ref.invalidate(recommendationsProvider),
                ),
              ],
            ),
          ),
          data: (recommendations) => recommendations.needsMoreData
              ? _NeedsMoreData(recommendations: recommendations)
              : _Recommendations(recommendations: recommendations),
        );
  }
}

class _NeedsMoreData extends StatelessWidget {
  const _NeedsMoreData({required this.recommendations});

  final Recommendations recommendations;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.all(VocaboSpacing.xl),
            decoration: BoxDecoration(
              color: VocaboColors.surfaceContainerLow,
              borderRadius: VocaboRadius.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: VocaboColors.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: VocaboColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: VocaboSpacing.md),
                Text(
                  l10n.forYouNeedsMoreTitle(recommendations.required),
                  style: VocaboTypography.titleLg,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VocaboSpacing.xs),
                Text(
                  l10n.forYouNeedsMoreBody(
                    recommendations.libraryWords,
                    recommendations.translatedWords,
                  ),
                  style: VocaboTypography.bodyMd.copyWith(
                    color: VocaboColors.neutral600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Recommendations extends ConsumerWidget {
  const _Recommendations({required this.recommendations});

  final Recommendations recommendations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final included =
        ref.watch(planStatusProvider).valueOrNull?.limits.collections ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = VocaboSpacing.md;
        final width = constraints.maxWidth;
        final wordColumns = width >= 900
            ? 3
            : width >= 560
            ? 2
            : 1;
        final wordWidth = (width - gap * (wordColumns - 1)) / wordColumns;
        final collectionColumns = width >= 1000
            ? 3
            : width >= 620
            ? 2
            : 1;
        final collectionWidth =
            (width - gap * (collectionColumns - 1)) / collectionColumns;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(VocaboSpacing.lg),
                decoration: BoxDecoration(
                  color: VocaboColors.surfaceContainerLowest,
                  borderRadius: VocaboRadius.lg,
                  boxShadow: [VocaboShadows.whisper],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome_outlined,
                          size: 16,
                          color: VocaboColors.primary,
                        ),
                        const SizedBox(width: VocaboSpacing.xs),
                        Flexible(
                          child: Text(
                            l10n.forYouTitle.toUpperCase(),
                            style: VocaboTypography.labelSm.copyWith(
                              color: VocaboColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VocaboSpacing.sm),
                    Text(
                      recommendations.summary,
                      style: VocaboTypography.bodyMd.copyWith(
                        color: VocaboColors.neutral700,
                        height: 1.45,
                      ),
                    ),
                    if (recommendations.createdAt case final createdAt?) ...[
                      const SizedBox(height: VocaboSpacing.xs),
                      Text(
                        updatedAtLabel(context, createdAt),
                        style: VocaboTypography.bodySm.copyWith(
                          color: VocaboColors.neutral,
                        ),
                      ),
                    ],
                    if (recommendations.unchanged) ...[
                      const SizedBox(height: VocaboSpacing.xs),
                      Text(
                        l10n.forYouUnchanged,
                        style: VocaboTypography.bodySm.copyWith(
                          color: VocaboColors.neutral,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (recommendations.words.isNotEmpty) ...[
                const SizedBox(height: VocaboSpacing.lg),
                Text(l10n.forYouWordsTitle, style: VocaboTypography.titleLg),
                const SizedBox(height: VocaboSpacing.md),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final word in recommendations.words)
                      SizedBox(
                        width: wordWidth,
                        child: RecommendedWordCard(
                          key: ValueKey(word.term),
                          word: word,
                        ),
                      ),
                  ],
                ),
              ],
              if (recommendations.collections.isNotEmpty) ...[
                const SizedBox(height: VocaboSpacing.xl),
                Text(
                  l10n.forYouCollectionsTitle,
                  style: VocaboTypography.titleLg,
                ),
                const SizedBox(height: VocaboSpacing.md),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final entry in recommendations.collections)
                      SizedBox(
                        width: collectionWidth,
                        child: CollectionCard(
                          collection: entry.collection,
                          reason: entry.reason,
                          locked: !included,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: VocaboSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

/// A recommended word: why it was picked, its translation on click and a
/// button that saves it to the library.
class RecommendedWordCard extends ConsumerStatefulWidget {
  const RecommendedWordCard({super.key, required this.word});

  final RecommendedWord word;

  @override
  ConsumerState<RecommendedWordCard> createState() =>
      _RecommendedWordCardState();
}

class _RecommendedWordCardState extends ConsumerState<RecommendedWordCard> {
  bool _revealed = false;
  bool _adding = false;
  late bool _inLibrary = widget.word.inLibrary;

  Future<void> _add() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _adding = true;
      _revealed = true;
    });
    try {
      final Vocabulary vocabulary =
          widget.word.vocabulary ??
          await ref.read(suggestedVocabularyProvider(widget.word.term).future);
      await ref
          .read(userVocabularyListProvider.notifier)
          .addVocabulary(vocabulary.toLibraryRequest());
      if (mounted) setState(() => _inLibrary = true);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.suggestedAddedToLibrary)),
      );
    } on ConflictException {
      if (mounted) setState(() => _inLibrary = true);
    } catch (e) {
      if (upgradeReasonFor(e) case final reason?) {
        ref.read(upgradePromptProvider.notifier).state = reason;
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.commonSomethingWrong)),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final word = widget.word;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: VocaboRadius.lg,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => setState(() => _revealed = !_revealed),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: VocaboRadius.lg,
          child: Padding(
            padding: const EdgeInsets.all(VocaboSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        word.term,
                        style: VocaboTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (_inLibrary)
                      Tooltip(
                        message: l10n.suggestedInLibrary,
                        child: const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: VocaboColors.tertiary,
                        ),
                      )
                    else if (_adding)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: l10n.suggestedAddToLibrary,
                        icon: const Icon(Icons.add_circle_outline, size: 22),
                        color: VocaboColors.primary,
                        visualDensity: VisualDensity.compact,
                        onPressed: _add,
                        style: const ButtonStyle(
                          mouseCursor: WidgetStatePropertyAll(
                            SystemMouseCursors.click,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: VocaboSpacing.xs),
                Text(
                  word.reason,
                  style: VocaboTypography.bodySm.copyWith(
                    color: VocaboColors.neutral600,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.topLeft,
                  child: _revealed
                      ? Padding(
                          padding: const EdgeInsets.only(top: VocaboSpacing.sm),
                          child: SuggestedTranslation(
                            term: word.term,
                            cached: word.vocabulary,
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
