import 'package:equatable/equatable.dart';

class VocabularyActivityPoint extends Equatable {
  final DateTime date;
  final int count;

  const VocabularyActivityPoint({required this.date, required this.count});

  factory VocabularyActivityPoint.fromJson(Map<String, dynamic> json) {
    return VocabularyActivityPoint(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int,
    );
  }

  @override
  List<Object> get props => [date, count];
}

class VocabularyWeeklyActivityPoint extends Equatable {
  final DateTime weekStart;
  final int count;

  const VocabularyWeeklyActivityPoint({
    required this.weekStart,
    required this.count,
  });

  factory VocabularyWeeklyActivityPoint.fromJson(Map<String, dynamic> json) {
    return VocabularyWeeklyActivityPoint(
      weekStart: DateTime.parse(json['week_start'] as String),
      count: json['count'] as int,
    );
  }

  @override
  List<Object> get props => [weekStart, count];
}

class VocabularyStats extends Equatable {
  final int totalWords;
  final int wordsToday;
  final int wordsThisWeek;
  final int wordsLastWeek;
  final int currentStreak;
  final int longestStreak;
  final int activeDays;
  final List<VocabularyActivityPoint> dailyActivity;
  final List<VocabularyWeeklyActivityPoint> weeklyActivity;

  const VocabularyStats({
    required this.totalWords,
    required this.wordsToday,
    required this.wordsThisWeek,
    required this.wordsLastWeek,
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDays,
    required this.dailyActivity,
    required this.weeklyActivity,
  });

  factory VocabularyStats.fromJson(Map<String, dynamic> json) {
    return VocabularyStats(
      totalWords: json['total_words'] as int,
      wordsToday: json['words_today'] as int,
      wordsThisWeek: json['words_this_week'] as int,
      wordsLastWeek: json['words_last_week'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      activeDays: json['active_days'] as int,
      dailyActivity: (json['daily_activity'] as List<dynamic>)
          .map(
            (item) =>
                VocabularyActivityPoint.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      weeklyActivity: (json['weekly_activity'] as List<dynamic>)
          .map(
            (item) => VocabularyWeeklyActivityPoint.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  double get weeklyChangePercent {
    if (wordsLastWeek == 0) return wordsThisWeek == 0 ? 0 : 100;
    return (wordsThisWeek - wordsLastWeek) / wordsLastWeek * 100;
  }

  @override
  List<Object> get props => [
    totalWords,
    wordsToday,
    wordsThisWeek,
    wordsLastWeek,
    currentStreak,
    longestStreak,
    activeDays,
    dailyActivity,
    weeklyActivity,
  ];
}
