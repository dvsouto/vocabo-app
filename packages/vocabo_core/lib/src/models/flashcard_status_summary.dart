import 'package:equatable/equatable.dart';

class FlashcardStatusSummary extends Equatable {
  final int totalActive;
  final int dueCount;
  final int completedCount;
  final int archivedCount;
  final bool hasActiveSession;
  final DateTime? nextReviewAt;

  const FlashcardStatusSummary({
    required this.totalActive,
    required this.dueCount,
    required this.completedCount,
    required this.archivedCount,
    required this.hasActiveSession,
    this.nextReviewAt,
  });

  factory FlashcardStatusSummary.fromJson(Map<String, dynamic> json) {
    return FlashcardStatusSummary(
      totalActive: json['total_active'] as int,
      dueCount: json['due_count'] as int,
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

  /// True when every card is scheduled for the future and a countdown should
  /// be shown instead of the start button.
  bool get isWaiting => hasCards && !canStartSession && nextReviewAt != null;

  @override
  List<Object?> get props => [
    totalActive,
    dueCount,
    completedCount,
    archivedCount,
    hasActiveSession,
    nextReviewAt,
  ];
}

class FlashcardConfig extends Equatable {
  final List<int> stages;
  final int cardsPerSession;

  const FlashcardConfig({required this.stages, required this.cardsPerSession});

  factory FlashcardConfig.fromJson(Map<String, dynamic> json) {
    return FlashcardConfig(
      stages: (json['stages'] as List<dynamic>)
          .map((stage) => stage as int)
          .toList(growable: false),
      cardsPerSession: json['cards_per_session'] as int,
    );
  }

  @override
  List<Object?> get props => [stages, cardsPerSession];
}

class UserPreferences extends Equatable {
  final bool showTranslations;

  const UserPreferences({this.showTranslations = true});

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      showTranslations: json['show_translations'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {'show_translations': showTranslations};

  UserPreferences copyWith({bool? showTranslations}) {
    return UserPreferences(
      showTranslations: showTranslations ?? this.showTranslations,
    );
  }

  @override
  List<Object?> get props => [showTranslations];
}
