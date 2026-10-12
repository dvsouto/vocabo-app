import 'package:equatable/equatable.dart';

class VocabularyActivityPoint extends Equatable {
  final DateTime date;

  /// Words added that day.
  final int count;

  /// Flashcards reviewed that day.
  final int reviews;

  const VocabularyActivityPoint({
    required this.date,
    required this.count,
    this.reviews = 0,
  });

  factory VocabularyActivityPoint.fromJson(Map<String, dynamic> json) {
    return VocabularyActivityPoint(
      date: DateTime.parse(json['date'] as String),
      count: json['count'] as int,
      reviews: json['reviews'] as int? ?? 0,
    );
  }

  bool get isActive => count > 0 || reviews > 0;

  @override
  List<Object> get props => [date, count, reviews];
}

class VocabularyWeeklyActivityPoint extends Equatable {
  final DateTime weekStart;

  /// Words added that week.
  final int count;

  /// Flashcards reviewed that week.
  final int reviews;

  const VocabularyWeeklyActivityPoint({
    required this.weekStart,
    required this.count,
    this.reviews = 0,
  });

  factory VocabularyWeeklyActivityPoint.fromJson(Map<String, dynamic> json) {
    return VocabularyWeeklyActivityPoint(
      weekStart: DateTime.parse(json['week_start'] as String),
      count: json['count'] as int,
      reviews: json['reviews'] as int? ?? 0,
    );
  }

  @override
  List<Object> get props => [weekStart, count, reviews];
}

/// How the flashcard answers were rated across every review.
class ReviewEvaluations extends Equatable {
  final int blank;
  final int fuzzy;
  final int clear;

  const ReviewEvaluations({this.blank = 0, this.fuzzy = 0, this.clear = 0});

  factory ReviewEvaluations.fromJson(Map<String, dynamic>? json) {
    return ReviewEvaluations(
      blank: json?['hard'] as int? ?? 0,
      fuzzy: json?['medium'] as int? ?? 0,
      clear: json?['easy'] as int? ?? 0,
    );
  }

  int get total => blank + fuzzy + clear;

  /// Share of answers rated clear, from 0 to 1.
  double get clearRate => total == 0 ? 0 : clear / total;

  @override
  List<Object> get props => [blank, fuzzy, clear];
}

class VocabularyStats extends Equatable {
  final int totalWords;
  final int wordsToday;
  final int wordsThisWeek;
  final int wordsLastWeek;

  /// Consecutive days with a word added or a flashcard reviewed.
  final int currentStreak;
  final int longestStreak;
  final int activeDays;
  final int reviewsTotal;
  final int reviewsToday;
  final int reviewsThisWeek;
  final int reviewsLastWeek;
  final ReviewEvaluations evaluations;
  final int cardsInRotation;
  final int cardsMastered;
  final int cardsArchived;

  /// Active flashcards per stage, index aligned with the stage list.
  final List<int> stageDistribution;
  final List<VocabularyActivityPoint> dailyActivity;
  final List<VocabularyWeeklyActivityPoint> weeklyActivity;

  /// False on the free plan: the weekly history, answers and memory
  /// strength are left out.
  final bool fullStats;

  const VocabularyStats({
    required this.totalWords,
    required this.wordsToday,
    required this.wordsThisWeek,
    required this.wordsLastWeek,
    required this.currentStreak,
    required this.longestStreak,
    required this.activeDays,
    this.reviewsTotal = 0,
    this.reviewsToday = 0,
    this.reviewsThisWeek = 0,
    this.reviewsLastWeek = 0,
    this.evaluations = const ReviewEvaluations(),
    this.cardsInRotation = 0,
    this.cardsMastered = 0,
    this.cardsArchived = 0,
    this.stageDistribution = const [],
    required this.dailyActivity,
    required this.weeklyActivity,
    this.fullStats = true,
  });

  factory VocabularyStats.fromJson(Map<String, dynamic> json) {
    final flashcards = json['flashcards'] as Map<String, dynamic>?;
    final stages = (json['stage_distribution'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();

    return VocabularyStats(
      totalWords: json['total_words'] as int,
      wordsToday: json['words_today'] as int,
      wordsThisWeek: json['words_this_week'] as int,
      wordsLastWeek: json['words_last_week'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      activeDays: json['active_days'] as int,
      reviewsTotal: json['reviews_total'] as int? ?? 0,
      reviewsToday: json['reviews_today'] as int? ?? 0,
      reviewsThisWeek: json['reviews_this_week'] as int? ?? 0,
      reviewsLastWeek: json['reviews_last_week'] as int? ?? 0,
      evaluations: ReviewEvaluations.fromJson(
        json['evaluations'] as Map<String, dynamic>?,
      ),
      cardsInRotation: flashcards?['in_rotation'] as int? ?? 0,
      cardsMastered: flashcards?['mastered'] as int? ?? 0,
      cardsArchived: flashcards?['archived'] as int? ?? 0,
      stageDistribution: [for (final stage in stages) stage['count'] as int],
      dailyActivity: (json['daily_activity'] as List<dynamic>)
          .map(
            (item) =>
                VocabularyActivityPoint.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      fullStats: json['full_stats'] as bool? ?? true,
      weeklyActivity: (json['weekly_activity'] as List<dynamic>? ?? const [])
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
    reviewsTotal,
    reviewsToday,
    reviewsThisWeek,
    reviewsLastWeek,
    evaluations,
    cardsInRotation,
    cardsMastered,
    cardsArchived,
    stageDistribution,
    dailyActivity,
    weeklyActivity,
    fullStats,
  ];
}
