import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/pro/plan_providers.dart';
import 'package:vocabo_desktop/src/pro/pro_feature_gate.dart';
import 'package:vocabo_desktop/src/providers/flashcard_providers.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcards_completion.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcards_home.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcards_session.dart';
import 'package:vocabo_desktop/src/widgets/section_tabs.dart';

/// Flashcards with one tab per deck: the library words and the words of
/// the added collections.
class FlashcardsContent extends ConsumerWidget {
  const FlashcardsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(flashcardsDeckTabProvider);

    return ProviderScope(
      key: ValueKey(deck),
      overrides: [currentFlashcardDeckProvider.overrideWithValue(deck)],
      child: _DeckView(deck: deck),
    );
  }
}

class _DeckView extends ConsumerStatefulWidget {
  const _DeckView({required this.deck});

  final FlashcardDeck deck;

  @override
  ConsumerState<_DeckView> createState() => _DeckViewState();
}

class _DeckViewState extends ConsumerState<_DeckView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOnEnter());
  }

  bool get _isLocked =>
      widget.deck == FlashcardDeck.collections &&
      !(ref.read(planStatusProvider).valueOrNull?.limits.collections ?? false);

  /// The server is the source of truth: always reload the status when the
  /// tab opens and resume any session that was left open elsewhere.
  void _refreshOnEnter() {
    if (!mounted || _isLocked) return;

    ref.invalidate(flashcardDeckStatusProvider(widget.deck));

    final provider = flashcardDeckSessionProvider(widget.deck);
    final notifier = ref.read(provider.notifier);
    switch (ref.read(provider).phase) {
      case FlashcardsPhase.session:
      case FlashcardsPhase.loading:
        notifier.startSession();
      case FlashcardsPhase.completion:
        notifier.finishCompletion();
      case FlashcardsPhase.home:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = flashcardDeckSessionProvider(widget.deck);

    ref.listen(provider.select((state) => state.noticeNonce), (_, _) {
      final notice = ref.read(provider).notice;
      if (notice == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notice)));
    });

    final phase = ref.watch(provider.select((s) => s.phase));

    return Padding(
      padding: const EdgeInsets.all(VocaboSpacing.xl),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (phase) {
          FlashcardsPhase.home => _HomeLayout(
            key: const ValueKey('home'),
            deck: widget.deck,
          ),
          FlashcardsPhase.loading => const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          ),
          FlashcardsPhase.session => const FlashcardsSession(
            key: ValueKey('session'),
          ),
          FlashcardsPhase.completion => const FlashcardsCompletion(
            key: ValueKey('completion'),
          ),
        },
      ),
    );
  }
}

class _HomeLayout extends ConsumerWidget {
  const _HomeLayout({super.key, required this.deck});

  final FlashcardDeck deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isPro = ref.watch(planStatusProvider).valueOrNull?.isPro ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.flashcardsTitle, style: VocaboTypography.headlineSm),
        const SizedBox(height: VocaboSpacing.xs),
        Text(
          l10n.flashcardsTagline,
          style: VocaboTypography.bodyMd.copyWith(color: VocaboColors.neutral),
        ),
        const SizedBox(height: VocaboSpacing.md),
        Transform.translate(
          offset: const Offset(-VocaboSpacing.md, 0),
          child: SectionTabs(
            labels: [
              l10n.flashcardsDeckMyWords,
              l10n.flashcardsDeckCollections,
            ],
            selectedIndex: deck.index,
            trailing: isPro ? const {} : const {1: ProBadge()},
            onSelected: (index) =>
                ref.read(flashcardsDeckTabProvider.notifier).state =
                    FlashcardDeck.values[index],
          ),
        ),
        const SizedBox(height: VocaboSpacing.lg),
        Expanded(
          child: deck == FlashcardDeck.collections
              ? ProFeatureGate(
                  isIncluded: (limits) => limits.collections,
                  icon: Icons.collections_bookmark_outlined,
                  title: l10n.flashcardsCollectionsLockedTitle,
                  body: l10n.flashcardsCollectionsLockedBody,
                  child: const FlashcardsHome(),
                )
              : const FlashcardsHome(),
        ),
      ],
    );
  }
}
