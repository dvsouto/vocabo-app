import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcard_evaluation_bar.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

/// Color of the flashcard reviews series, next to the words added series.
const _reviewsColor = VocaboColors.tertiary;

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
            const SizedBox(height: VocaboSpacing.lg),
            _WeeklyChart(points: data.weeklyActivity),
            const SizedBox(height: VocaboSpacing.lg),
            _ResponsivePair(
              first: _AnswersCard(evaluations: data.evaluations),
              second: _MemoryStrengthCard(stats: data),
            ),
            const SizedBox(height: VocaboSpacing.lg),
            _DailyActivity(points: data.dailyActivity),
          ],
        ),
      ),
    );
  }
}

/// Two cards side by side, stacked when the window is narrow.
class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: [
              first,
              const SizedBox(height: VocaboSpacing.lg),
              second,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: first),
              const SizedBox(width: VocaboSpacing.lg),
              Expanded(child: second),
            ],
          ),
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    final clearRate = (stats.evaluations.clearRate * 100).round();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final width =
            (constraints.maxWidth - VocaboSpacing.md * (columns - 1)) / columns;
        return Wrap(
          spacing: VocaboSpacing.md,
          runSpacing: VocaboSpacing.md,
          children: [
            _MetricCard(
              width: width,
              icon: Icons.auto_stories_outlined,
              label: 'WORDS IN LIBRARY',
              value: '${stats.totalWords}',
              caption: '${stats.wordsThisWeek} added this week',
            ),
            _MetricCard(
              width: width,
              icon: Icons.local_fire_department_outlined,
              label: 'CURRENT STREAK',
              value: countLabel(stats.currentStreak, 'day'),
              caption: 'Best: ${countLabel(stats.longestStreak, 'day')}',
            ),
            _MetricCard(
              width: width,
              icon: Icons.style_outlined,
              label: 'FLASHCARDS REVIEWED',
              value: '${stats.reviewsTotal}',
              caption: stats.evaluations.total == 0
                  ? '${stats.reviewsThisWeek} this week'
                  : '$clearRate% answered clear',
            ),
            _MetricCard(
              width: width,
              icon: Icons.workspace_premium_outlined,
              label: 'WORDS MASTERED',
              value: '${stats.cardsMastered}',
              caption: '${stats.cardsInRotation} in rotation',
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
    required this.caption,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: VocaboTypography.bodySm.copyWith(
            color: VocaboColors.neutral600,
          ),
        ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.points});

  final List<VocabularyWeeklyActivityPoint> points;

  static const _barsHeight = 120.0;

  @override
  Widget build(BuildContext context) {
    final maxCount = points.fold<int>(
      1,
      (max, point) => math.max(max, math.max(point.count, point.reviews)),
    );

    double barHeight(int value) =>
        value == 0 ? 3 : math.max(8, value / maxCount * _barsHeight);

    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LAST 12 WEEKS', style: VocaboTypography.labelSm),
                    const SizedBox(height: VocaboSpacing.xs),
                    Text('Weekly activity', style: VocaboTypography.titleLg),
                  ],
                ),
              ),
              const _Legend(color: VocaboColors.primary, label: 'Words added'),
              const SizedBox(width: VocaboSpacing.md),
              const _Legend(color: _reviewsColor, label: 'Reviews'),
            ],
          ),
          const SizedBox(height: VocaboSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.map((point) {
              return Expanded(
                child: Tooltip(
                  message:
                      'Week of ${point.weekStart.day}/${point.weekStart.month}: '
                      '${countLabel(point.count, 'word')} added, '
                      '${countLabel(point.reviews, 'review')}',
                  child: Column(
                    children: [
                      SizedBox(
                        height: _barsHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Bar(
                              height: barHeight(point.count),
                              color: point.count == 0
                                  ? VocaboColors.neutral200
                                  : VocaboColors.primary,
                            ),
                            const SizedBox(width: 2),
                            _Bar(
                              height: barHeight(point.reviews),
                              color: point.reviews == 0
                                  ? VocaboColors.neutral200
                                  : _reviewsColor,
                            ),
                          ],
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
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 14),
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}

/// A labelled horizontal bar with its count, used by the breakdown cards.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
    this.leading,
  });

  final String label;
  final int value;
  final int total;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : value / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: VocaboSpacing.sm),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          SizedBox(
            width: leading == null ? 76 : 56,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VocaboTypography.bodySm,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: VocaboRadius.sm,
              child: LinearProgressIndicator(
                value: share,
                minHeight: 8,
                color: color,
                backgroundColor: VocaboColors.neutral200.withValues(alpha: 0.5),
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: VocaboTypography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.overline,
    required this.title,
    required this.child,
  });

  final String overline;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(overline, style: VocaboTypography.labelSm),
          const SizedBox(height: VocaboSpacing.xs),
          Text(title, style: VocaboTypography.titleLg),
          const SizedBox(height: VocaboSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _AnswersCard extends StatelessWidget {
  const _AnswersCard({required this.evaluations});

  final ReviewEvaluations evaluations;

  @override
  Widget build(BuildContext context) {
    final counts = {
      FlashcardEvaluation.hard: evaluations.blank,
      FlashcardEvaluation.medium: evaluations.fuzzy,
      FlashcardEvaluation.easy: evaluations.clear,
    };

    return _BreakdownCard(
      overline: 'FLASHCARD ANSWERS',
      title: 'How clear your recall is',
      child: evaluations.total == 0
          ? Text(
              'Review your flashcards to see how clearly you remember '
              'your words.',
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            )
          : Column(
              children: [
                for (final entry in counts.entries)
                  _BreakdownRow(
                    leading: ClarityIcon(
                      clarity: clarityOf(entry.key),
                      color: evaluationPalette(context, entry.key).foreground,
                      size: 14,
                    ),
                    label: clarityLabelOf(entry.key),
                    value: entry.value,
                    total: evaluations.total,
                    color: evaluationPalette(context, entry.key).foreground,
                  ),
              ],
            ),
    );
  }
}

class _MemoryStrengthCard extends StatelessWidget {
  const _MemoryStrengthCard({required this.stats});

  final VocabularyStats stats;

  @override
  Widget build(BuildContext context) {
    final stages = stats.stageDistribution;
    final total =
        stages.fold<int>(0, (sum, count) => sum + count) + stats.cardsMastered;

    return _BreakdownCard(
      overline: 'MEMORY STRENGTH',
      title: 'Where your words are',
      child: total == 0
          ? Text(
              'Add words to your library to start building memory.',
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            )
          : Column(
              children: [
                for (var index = 0; index < stages.length; index++)
                  _BreakdownRow(
                    label:
                        MemoryStrength.stageNames[math.min(
                          index,
                          MemoryStrength.stageNames.length - 1,
                        )],
                    value: stages[index],
                    total: total,
                    color: VocaboColors.primary.withValues(
                      alpha: 0.35 + index / stages.length * 0.65,
                    ),
                  ),
                _BreakdownRow(
                  label: MemoryStrength.masteredName,
                  value: stats.cardsMastered,
                  total: total,
                  color: _reviewsColor,
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
                child: Tooltip(
                  message:
                      '${countLabel(point.count, 'word')} added, '
                      '${countLabel(point.reviews, 'review')}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VocaboSpacing.xs,
                      vertical: VocaboSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: point.isActive
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
                        Text(
                          '${point.reviews} rev.',
                          maxLines: 1,
                          style: VocaboTypography.labelSm.copyWith(
                            color: point.reviews > 0
                                ? _reviewsColor
                                : VocaboColors.neutral,
                          ),
                        ),
                      ],
                    ),
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
