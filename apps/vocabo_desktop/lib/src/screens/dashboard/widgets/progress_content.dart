import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class ProgressContent extends ConsumerWidget {
  const ProgressContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(vocabularyStatsProvider);

    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: VocaboSpacing.md),
            Text(
              'Could not load your progress',
              style: VocaboTypography.titleLg,
            ),
            const SizedBox(height: VocaboSpacing.sm),
            VocaboPrimaryButton(
              label: 'Try Again',
              onPressed: () => ref.invalidate(vocabularyStatsProvider),
            ),
          ],
        ),
      ),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.all(VocaboSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Learning Progress', style: VocaboTypography.headlineSm),
            const SizedBox(height: VocaboSpacing.xs),
            Text(
              'A clear view of the habit behind your vocabulary.',
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            const SizedBox(height: VocaboSpacing.xl),
            _MetricsGrid(stats: data),
            const SizedBox(height: VocaboSpacing.xl),
            _WeeklyChart(points: data.weeklyActivity),
            const SizedBox(height: VocaboSpacing.xl),
            _DailyActivity(points: data.dailyActivity),
          ],
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - VocaboSpacing.md * 3) / 4;
        return Wrap(
          spacing: VocaboSpacing.md,
          runSpacing: VocaboSpacing.md,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.auto_stories_outlined,
              label: 'TOTAL WORDS',
              value: '${stats.totalWords}',
            ),
            _MetricCard(
              width: width,
              icon: Icons.local_fire_department_outlined,
              label: 'CURRENT STREAK',
              value: '${stats.currentStreak} days',
            ),
            _MetricCard(
              width: width,
              icon: Icons.emoji_events_outlined,
              label: 'BEST STREAK',
              value: '${stats.longestStreak} days',
            ),
            _MetricCard(
              width: width,
              icon: Icons.calendar_today_outlined,
              label: 'ACTIVE DAYS',
              value: '${stats.activeDays}',
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: math.max(170, width),
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: VocaboRadius.lg,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: VocaboColors.primary, size: 22),
          const SizedBox(height: VocaboSpacing.md),
          Text(value, style: VocaboTypography.titleLg),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            label,
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.points});

  final List<VocabularyWeeklyActivityPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxCount = points.fold<int>(
      1,
      (max, point) => math.max(max, point.count),
    );

    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('12-WEEK ACTIVITY', style: VocaboTypography.labelSm),
          const SizedBox(height: VocaboSpacing.xs),
          Text('Words added over time', style: VocaboTypography.titleLg),
          const SizedBox(height: VocaboSpacing.xl),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map((point) {
                final height = point.count == 0
                    ? 4.0
                    : math.max(12.0, point.count / maxCount * 150);
                return Expanded(
                  child: Tooltip(
                    message: '${point.count} words',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: point.count == 0
                                  ? VocaboColors.neutral200
                                  : VocaboColors.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: VocaboSpacing.sm),
                          Text(
                            '${point.weekStart.day}/${point.weekStart.month}',
                            maxLines: 1,
                            style: VocaboTypography.labelSm.copyWith(
                              color: VocaboColors.neutral,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyActivity extends StatelessWidget {
  const _DailyActivity({required this.points});

  final List<VocabularyActivityPoint> points;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LAST 7 DAYS', style: VocaboTypography.labelSm),
        const SizedBox(height: VocaboSpacing.md),
        Row(
          children: points.map((point) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: VocaboSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VocaboSpacing.sm,
                    vertical: VocaboSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: point.count > 0
                        ? VocaboColors.primary50
                        : VocaboColors.surfaceContainerLow,
                    borderRadius: VocaboRadius.md,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _weekdays[point.date.weekday - 1],
                        style: VocaboTypography.labelSm.copyWith(
                          color: VocaboColors.neutral,
                        ),
                      ),
                      const SizedBox(height: VocaboSpacing.sm),
                      Text('${point.count}', style: VocaboTypography.titleLg),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
