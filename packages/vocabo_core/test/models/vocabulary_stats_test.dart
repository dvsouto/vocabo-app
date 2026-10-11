import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  test('parses vocabulary statistics and calculates weekly change', () {
    final stats = VocabularyStats.fromJson({
      'total_words': 42,
      'words_today': 3,
      'words_this_week': 12,
      'words_last_week': 8,
      'current_streak': 4,
      'longest_streak': 9,
      'active_days': 18,
      'daily_activity': [
        {'date': '2026-10-09', 'count': 3},
      ],
      'weekly_activity': [
        {'week_start': '2026-10-05', 'count': 12},
      ],
    });

    expect(stats.totalWords, 42);
    expect(stats.dailyActivity.single.count, 3);
    expect(stats.weeklyActivity.single.weekStart, DateTime(2026, 10, 5));
    expect(stats.weeklyChangePercent, 50);
  });

  test('reports a neutral weekly change when both weeks are empty', () {
    const stats = VocabularyStats(
      totalWords: 0,
      wordsToday: 0,
      wordsThisWeek: 0,
      wordsLastWeek: 0,
      currentStreak: 0,
      longestStreak: 0,
      activeDays: 0,
      dailyActivity: [],
      weeklyActivity: [],
    );

    expect(stats.weeklyChangePercent, 0);
  });
}
