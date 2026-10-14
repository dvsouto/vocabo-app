import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class StatsSection extends ConsumerWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(vocabularyStatsProvider);

    return stats.when(
      data: (data) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _DailyProgressCard(stats: data)),
            const SizedBox(width: VocaboSpacing.md),
            Expanded(child: _SummaryCard(stats: data)),
          ],
        ),
      ),
      loading: () => const SizedBox(
        height: 164,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Container(
        padding: const EdgeInsets.all(VocaboSpacing.lg),
        decoration: BoxDecoration(
          color: VocaboColors.surfaceContainerLow,
          borderRadius: VocaboRadius.lg,
        ),
        child: Row(
          children: [
            const Icon(Icons.insights_outlined, color: VocaboColors.neutral),
            const SizedBox(width: VocaboSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.statsInsightsUnavailable,
                style: VocaboTypography.bodyMd,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(vocabularyStatsProvider),
              child: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.lg,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.statsDailyProgress,
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.tertiary,
            ),
          ),
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            context.l10n.statsDaysInARow(stats.currentStreak),
            style: VocaboTypography.headlineSm,
          ),
          const SizedBox(height: VocaboSpacing.md),
          _MiniBarChart(points: stats.dailyActivity),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart({required this.points});

  final List<VocabularyActivityPoint> points;

  @override
  Widget build(BuildContext context) {
    int activity(VocabularyActivityPoint point) => point.count + point.reviews;
    final maxCount = points.fold<int>(
      1,
      (max, point) => math.max(max, activity(point)),
    );

    final l10n = context.l10n;

    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final count = activity(point);
          final height = count == 0
              ? 4.0
              : math.max(10.0, count / maxCount * 48);
          return Expanded(
            child: Tooltip(
              message: l10n.statsDayTooltip(point.count, point.reviews),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 16,
                  height: height,
                  decoration: BoxDecoration(
                    color: count == 0
                        ? VocaboColors.neutral200
                        : VocaboColors.primary.withValues(
                            alpha: 0.45 + count / maxCount * 0.55,
                          ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final VocabularyStats stats;

  String _comparisonText(AppLocalizations l10n) {
    final change = stats.weeklyChangePercent;
    if (stats.wordsThisWeek == 0) {
      return stats.reviewsThisWeek == 0
          ? l10n.statsStartTheWeek
          : l10n.statsKeepLibraryGrowing;
    }
    if (stats.wordsLastWeek == 0) {
      return l10n.statsFreshWeek;
    }
    if (change == 0) {
      return l10n.statsMatchingPace;
    }
    final percentage = change.abs().round();
    return change > 0
        ? l10n.statsPaceHigher(percentage)
        : l10n.statsPaceLower(percentage);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.primary,
        borderRadius: VocaboRadius.lg,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: 0.3),
              size: 40,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.statsThisWeek,
                style: VocaboTypography.labelSm.copyWith(color: Colors.white),
              ),
              const SizedBox(height: VocaboSpacing.sm),
              Text(
                l10n.countNewWords(stats.wordsThisWeek),
                style: VocaboTypography.headlineSm.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: VocaboSpacing.xs),
              Text(
                l10n.statsFlashcardsReviewed(stats.reviewsThisWeek),
                style: VocaboTypography.bodyMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VocaboSpacing.sm),
              Text(
                _comparisonText(l10n),
                style: VocaboTypography.bodySm.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
