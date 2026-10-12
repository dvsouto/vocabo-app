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

  test('parses flashcard review statistics', () {
    final stats = VocabularyStats.fromJson({
      'total_words': 7,
      'words_today': 0,
      'words_this_week': 0,
      'words_last_week': 0,
      'current_streak': 2,
      'longest_streak': 2,
      'active_days': 2,
      'reviews_total': 10,
      'reviews_today': 4,
      'reviews_this_week': 10,
      'reviews_last_week': 0,
      'evaluations': {'hard': 1, 'medium': 4, 'easy': 5},
      'flashcards': {'in_rotation': 6, 'mastered': 1, 'archived': 0},
      'stage_distribution': [
        {'stage_index': 0, 'count': 2},
        {'stage_index': 1, 'count': 4},
      ],
      'daily_activity': [
        {'date': '2026-10-11', 'count': 0, 'reviews': 4},
      ],
      'weekly_activity': [
        {'week_start': '2026-10-05', 'count': 0, 'reviews': 10},
      ],
    });

    expect(stats.evaluations.clearRate, 0.5);
    expect(stats.cardsMastered, 1);
    expect(stats.stageDistribution, [2, 4]);
    expect(stats.dailyActivity.single.isActive, isTrue);
    expect(stats.weeklyActivity.single.reviews, 10);
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
