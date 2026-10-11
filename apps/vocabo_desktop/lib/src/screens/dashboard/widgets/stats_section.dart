import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
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
                'Learning insights are temporarily unavailable.',
                style: VocaboTypography.bodyMd,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(vocabularyStatsProvider),
              child: const Text('Retry'),
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
            'DAILY PROGRESS',
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.tertiary,
            ),
          ),
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            stats.currentStreak == 1
                ? '1 Day Straight'
                : '${stats.currentStreak} Days Straight',
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
    final maxCount = points.fold<int>(
      1,
      (max, point) => math.max(max, point.count),
    );

    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final height = point.count == 0
              ? 4.0
              : math.max(10.0, point.count / maxCount * 48);
          return Expanded(
            child: Tooltip(
              message: '${point.count} words',
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 16,
                  height: height,
                  decoration: BoxDecoration(
                    color: point.count == 0
                        ? VocaboColors.neutral200
                        : VocaboColors.primary.withValues(
                            alpha: 0.45 + point.count / maxCount * 0.55,
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

  String get _comparisonText {
    final change = stats.weeklyChangePercent;
    if (stats.wordsThisWeek == 0) {
      return 'Add a word today to start building your weekly momentum.';
    }
    if (stats.wordsLastWeek == 0) {
      return 'A fresh week is underway. Keep adding words to build a consistent rhythm.';
    }
    if (change == 0) {
      return 'You are matching last week’s pace. One more word puts you ahead.';
    }
    final percentage = change.abs().round();
    return change > 0
        ? 'Your pace is $percentage% higher than last week. Keep the momentum.'
        : 'Your pace is $percentage% below last week. A short session can close the gap.';
  }

  @override
  Widget build(BuildContext context) {
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
                'SUMMARY',
                style: VocaboTypography.labelSm.copyWith(color: Colors.white),
              ),
              const SizedBox(height: VocaboSpacing.sm),
              Text(
                '${stats.wordsThisWeek} Words learned this week',
                style: VocaboTypography.headlineSm.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: VocaboSpacing.sm),
              Text(
                _comparisonText,
                style: VocaboTypography.bodySm.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
