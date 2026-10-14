import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';

class FlashcardsHome extends ConsumerWidget {
  const FlashcardsHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(currentFlashcardDeckProvider);
    final status = ref.watch(flashcardDeckStatusProvider(deck));

    return status.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: VocaboSpacing.md),
            Text(
              context.l10n.flashcardsLoadFailed,
              style: VocaboTypography.titleLg,
            ),
            const SizedBox(height: VocaboSpacing.sm),
            VocaboPrimaryButton(
              label: context.l10n.commonTryAgain,
              onPressed: () =>
                  ref.invalidate(flashcardDeckStatusProvider(deck)),
            ),
          ],
        ),
      ),
      data: (summary) => _HomeBody(summary: summary, deck: deck),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.summary, required this.deck});

  final FlashcardStatusSummary summary;
  final FlashcardDeck deck;

  bool get _isCollections => deck == FlashcardDeck.collections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClaimFocus(
      debugLabel: 'flashcards-home',
      onKeyEvent: (node, event) {
        final isEnter =
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter;
        if (event is! KeyDownEvent || !isEnter || !summary.canStartSession) {
          return KeyEventResult.ignored;
        }
        ref.read(flashcardDeckSessionProvider(deck).notifier).startSession();
        return KeyEventResult.handled;
      },
      child: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(VocaboSpacing.xxl),
                decoration: BoxDecoration(
                  color: VocaboColors.surfaceContainerLow,
                  borderRadius: VocaboRadius.lg,
                ),
                child: _buildState(context, ref),
              ),
              const SizedBox(height: VocaboSpacing.lg),
              _buildFooter(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildState(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (!summary.hasCards && summary.completedCount == 0 && _isCollections) {
      return _HeroContent(
        icon: Icons.collections_bookmark_outlined,
        title: l10n.flashcardsCollectionsEmptyTitle,
        subtitle: l10n.flashcardsCollectionsEmptySubtitle,
        action: VocaboPrimaryButton(
          label: l10n.flashcardsExploreCollections,
          onPressed: () {
            ref.read(libraryTabProvider.notifier).state =
                LibraryTab.collections;
            ref.read(openCollectionIdProvider.notifier).state = null;
            ref.read(dashboardSectionProvider.notifier).state =
                DashboardSection.library;
          },
        ),
      );
    }

    if (!summary.hasCards && summary.completedCount == 0) {
      return _HeroContent(
        icon: Icons.style_outlined,
        title: l10n.flashcardsEmptyTitle,
        subtitle: l10n.flashcardsEmptySubtitle,
      );
    }

    if (summary.canStartSession) {
      return _HeroContent(
        icon: Icons.style_outlined,
        title: _readyTitle(l10n),
        subtitle: _readySubtitle(l10n),
        action: VocaboPrimaryButton(
          label: summary.hasActiveSession
              ? l10n.flashcardsContinueReviewing
              : l10n.flashcardsReviewNow,
          isExpanded: true,
          trailing: VocaboKeyCap(
            l10n.flashcardsKeyEnter,
            color: VocaboColors.onPrimary,
          ),
          onPressed: () => ref
              .read(flashcardDeckSessionProvider(deck).notifier)
              .startSession(),
        ),
      );
    }

    if (summary.isWaiting) {
      return _HeroContent(
        icon: Icons.nights_stay_outlined,
        title: l10n.flashcardsWaitingTitle,
        subtitle: l10n.flashcardsWaitingSubtitle,
        action: FlashcardCountdown(
          target: summary.nextReviewAt!,
          onFinished: () => ref.invalidate(flashcardDeckStatusProvider(deck)),
        ),
      );
    }

    return _HeroContent(
      icon: Icons.workspace_premium_outlined,
      title: l10n.flashcardsAllMasteredTitle,
      subtitle: l10n.flashcardsAllMasteredSubtitle,
    );
  }

  String _readyTitle(AppLocalizations l10n) {
    if (summary.dueCount == 0) return l10n.flashcardsSessionWaiting;
    return l10n.flashcardsWordsWaiting(summary.dueCount);
  }

  String _readySubtitle(AppLocalizations l10n) {
    final minutes = summary.estimatedMinutes();
    final parts = <String>[
      if (summary.dueNew > 0) l10n.flashcardsDueNew(summary.dueNew),
      if (summary.dueReturning > 0)
        l10n.flashcardsDueReturning(summary.dueReturning),
      if (summary.dueLongTerm > 0)
        l10n.flashcardsDueLongTerm(summary.dueLongTerm),
    ];

    if (minutes == 0) return l10n.flashcardsPickUpWhereYouLeft;

    final duration = l10n.flashcardsAboutMinutes(minutes);
    return parts.isEmpty ? duration : '$duration · ${parts.join(', ')}';
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final parts = <String>[
      l10n.flashcardsInRotation(summary.totalActive),
      if (summary.completedCount > 0)
        l10n.flashcardsMasteredCount(summary.completedCount),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          parts.join(' · '),
          style: VocaboTypography.bodySm.copyWith(color: VocaboColors.neutral),
        ),
        if (!_isCollections) ...[
          const SizedBox(width: VocaboSpacing.sm),
          TextButton(
            onPressed: () {
              final canArchive =
                  ref.read(planStatusProvider).valueOrNull?.limits.archive ??
                  true;
              if (canArchive) {
                showArchivedFlashcardsDialog(context);
              } else {
                showPaywall(
                  context,
                  const UpgradeReason(UpgradeTrigger.feature),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: VocaboColors.neutral,
              minimumSize: const Size(44, 32),
              padding: const EdgeInsets.symmetric(horizontal: VocaboSpacing.sm),
              textStyle: VocaboTypography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
              ),
              enabledMouseCursor: SystemMouseCursors.click,
            ),
            child: Text(
              summary.archivedCount > 0
                  ? l10n.flashcardsArchivedWithCount(summary.archivedCount)
                  : l10n.flashcardsArchivedButton,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: VocaboColors.primary50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: VocaboColors.primary, size: 28),
        ),
        const SizedBox(height: VocaboSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: VocaboTypography.headlineSm,
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: VocaboTypography.bodyMd.copyWith(color: VocaboColors.neutral),
        ),
        if (action != null) ...[
          const SizedBox(height: VocaboSpacing.xl),
          action!,
        ],
      ],
    );
  }
}
