import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/data/mock_data.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _DailyProgressCard()),
        const SizedBox(width: VocaboSpacing.md),
        const Expanded(child: _SummaryCard()),
      ],
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard();

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
            '${MockDashboardData.streakDays} Days Straight',
            style: VocaboTypography.headlineSm,
          ),
          const SizedBox(height: VocaboSpacing.md),
          const _MiniBarChart(),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  const _MiniBarChart();

  static const _barHeights = [24.0, 32.0, 18.0, 40.0, 28.0, 36.0, 44.0];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: _barHeights.map((h) {
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Container(
            width: 16,
            height: h,
            decoration: BoxDecoration(
              color: VocaboColors.primary.withValues(
                alpha: h / 44.0 * 0.6 + 0.4,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

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
                '${MockDashboardData.wordsThisWeek} Words learned this week',
                style:
                    VocaboTypography.headlineSm.copyWith(color: Colors.white),
              ),
              const SizedBox(height: VocaboSpacing.sm),
              Text(
                "You're expanding your linguistic range by 15% compared to last month. Keep the momentum.",
                style: VocaboTypography.bodySm.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
