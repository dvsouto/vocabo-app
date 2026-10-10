import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/flashcard_providers.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/archived_flashcards_dialog.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcard_countdown.dart';

class FlashcardsHome extends ConsumerWidget {
  const FlashcardsHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(flashcardStatusProvider);

    return status.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: VocaboSpacing.md),
            Text(
              'Could not load your flashcards',
              style: VocaboTypography.titleLg,
            ),
            const SizedBox(height: VocaboSpacing.sm),
            VocaboPrimaryButton(
              label: 'Try Again',
              onPressed: () => ref.invalidate(flashcardStatusProvider),
            ),
          ],
        ),
      ),
      data: (summary) => _HomeBody(summary: summary),
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.summary});

  final FlashcardStatusSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
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
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildState(BuildContext context, WidgetRef ref) {
    if (!summary.hasCards && summary.completedCount == 0) {
      return const _HeroContent(
        icon: Icons.style_outlined,
        title: 'Ready to grow your vocabulary? 🚀',
        subtitle:
            'Add words to your library and they will show up here as flashcards to review.',
      );
    }

    if (summary.canStartSession) {
      return _HeroContent(
        icon: Icons.style_outlined,
        title: 'Ready for a challenge? 🎯',
        subtitle: 'Every card you master is one more step toward fluency.',
        action: VocaboPrimaryButton(
          label: summary.hasActiveSession ? 'Continue review' : 'Start review',
          isExpanded: true,
          onPressed: () =>
              ref.read(flashcardSessionProvider.notifier).startSession(),
        ),
      );
    }

    if (summary.isWaiting) {
      return _HeroContent(
        icon: Icons.celebration_outlined,
        title: 'Nice work, you are all caught up!',
        subtitle: 'Your next review unlocks in',
        action: FlashcardCountdown(
          target: summary.nextReviewAt!,
          onFinished: () => ref.invalidate(flashcardStatusProvider),
        ),
      );
    }

    return const _HeroContent(
      icon: Icons.emoji_events_outlined,
      title: 'Every card mastered 🏆',
      subtitle: 'Add new words to your library to keep the momentum going.',
    );
  }

  Widget _buildFooter(BuildContext context) {
    final parts = <String>[
      '${summary.totalActive} in rotation',
      if (summary.completedCount > 0) '${summary.completedCount} mastered',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          parts.join(' · '),
          style: VocaboTypography.bodySm.copyWith(color: VocaboColors.neutral),
        ),
        const SizedBox(width: VocaboSpacing.sm),
        TextButton(
          onPressed: () => showArchivedFlashcardsDialog(context),
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
                ? 'Archived (${summary.archivedCount})'
                : 'Archived',
          ),
        ),
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
