import 'package:equatable/equatable.dart';

class FlashcardStatusSummary extends Equatable {
  final int totalActive;
  final int dueCount;
  final int dueNew;
  final int dueReturning;
  final int dueLongTerm;
  final int completedCount;
  final int archivedCount;
  final bool hasActiveSession;
  final DateTime? nextReviewAt;

  const FlashcardStatusSummary({
    required this.totalActive,
    required this.dueCount,
    this.dueNew = 0,
    this.dueReturning = 0,
    this.dueLongTerm = 0,
    required this.completedCount,
    required this.archivedCount,
    required this.hasActiveSession,
    this.nextReviewAt,
  });

  factory FlashcardStatusSummary.fromJson(Map<String, dynamic> json) {
    return FlashcardStatusSummary(
      totalActive: json['total_active'] as int,
      dueCount: json['due_count'] as int,
      dueNew: json['due_new'] as int? ?? 0,
      dueReturning: json['due_returning'] as int? ?? 0,
      dueLongTerm: json['due_long_term'] as int? ?? 0,
      completedCount: json['completed_count'] as int? ?? 0,
      archivedCount: json['archived_count'] as int? ?? 0,
      hasActiveSession: json['has_active_session'] as bool? ?? false,
      nextReviewAt: json['next_review_at'] == null
          ? null
          : DateTime.parse(json['next_review_at'] as String),
    );
  }

  bool get hasCards => totalActive > 0;

  bool get canStartSession => hasActiveSession || dueCount > 0;

  /// Rough length of the next session, assuming about 20 seconds per card.
  int estimatedMinutes({int cardsPerSession = 15}) {
    final cards = dueCount < cardsPerSession ? dueCount : cardsPerSession;
    if (cards == 0) return 0;
    return ((cards * 20) / 60).ceil();
  }

  /// True when every card is scheduled for the future and a countdown should
  /// be shown instead of the start button.
  bool get isWaiting => hasCards && !canStartSession && nextReviewAt != null;

  @override
  List<Object?> get props => [
    totalActive,
    dueCount,
    dueNew,
    dueReturning,
    dueLongTerm,
    completedCount,
    archivedCount,
    hasActiveSession,
    nextReviewAt,
  ];
}

class FlashcardConfig extends Equatable {
  final List<int> stages;
  final int cardsPerSession;
  final List<int> reverseStageIntervals;

  const FlashcardConfig({
    required this.stages,
    required this.cardsPerSession,
    this.reverseStageIntervals = const [],
  });

  /// Mirrors the API defaults so the UI can render before the config loads.
  static const fallback = FlashcardConfig(
    stages: [0, 1, 3, 5, 7, 14, 28],
    cardsPerSession: 15,
    reverseStageIntervals: [7, 28],
  );

  factory FlashcardConfig.fromJson(Map<String, dynamic> json) {
    return FlashcardConfig(
      stages: (json['stages'] as List<dynamic>)
          .map((stage) => stage as int)
          .toList(growable: false),
      cardsPerSession: json['cards_per_session'] as int,
      reverseStageIntervals:
          (json['reverse_stage_intervals'] as List<dynamic>? ?? const [])
              .map((interval) => interval as int)
              .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [stages, cardsPerSession, reverseStageIntervals];
}

class UserPreferences extends Equatable {
  final bool showTranslations;
  final bool dailyReminderEnabled;

  /// Local time of day in 24h `HH:MM` format.
  final String dailyReminderTime;

  /// Voice of the pronunciation audio: `female` or `male`.
  final String voiceGender;

  const UserPreferences({
    this.showTranslations = true,
    this.dailyReminderEnabled = false,
    this.dailyReminderTime = '08:00',
    this.voiceGender = 'female',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      showTranslations: json['show_translations'] as bool? ?? true,
      dailyReminderEnabled: json['daily_reminder_enabled'] as bool? ?? false,
      dailyReminderTime: json['daily_reminder_time'] as String? ?? '08:00',
      voiceGender: json['voice_gender'] as String? ?? 'female',
    );
  }

  Map<String, dynamic> toJson() => {
    'show_translations': showTranslations,
    'daily_reminder_enabled': dailyReminderEnabled,
    'daily_reminder_time': dailyReminderTime,
    'voice_gender': voiceGender,
  };

  UserPreferences copyWith({
    bool? showTranslations,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
    String? voiceGender,
  }) {
    return UserPreferences(
      showTranslations: showTranslations ?? this.showTranslations,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      voiceGender: voiceGender ?? this.voiceGender,
    );
  }

  @override
  List<Object?> get props => [
    showTranslations,
    dailyReminderEnabled,
    dailyReminderTime,
    voiceGender,
  ];
}
