import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/enums/flashcard_status.dart';
import 'package:vocabo_core/src/enums/vocabulary_type.dart';
import 'package:vocabo_core/src/models/vocabulary.dart';

class FlashcardStageHistory extends Equatable {
  final int stageIndex;
  final int intervalDays;
  final String? shouldBeAt;
  final String? dateAt;
  final DateTime? completedAt;
  final int daysLate;

  const FlashcardStageHistory({
    required this.stageIndex,
    required this.intervalDays,
    this.shouldBeAt,
    this.dateAt,
    this.completedAt,
    this.daysLate = 0,
  });

  factory FlashcardStageHistory.fromJson(Map<String, dynamic> json) {
    return FlashcardStageHistory(
      stageIndex: json['stage_index'] as int,
      intervalDays: json['interval_days'] as int,
      shouldBeAt: json['should_be_at'] as String?,
      dateAt: json['date_at'] as String?,
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      daysLate: json['days_late'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    stageIndex,
    intervalDays,
    shouldBeAt,
    dateAt,
    completedAt,
    daysLate,
  ];
}

class Flashcard extends Equatable {
  final String id;
  final String userVocabularyId;
  final FlashcardStatus status;
  final int currentStageIndex;
  final String stageLabel;
  final DateTime? nextReviewAt;
  final bool hasRegressed;
  final List<FlashcardStageHistory> stagesHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastEvaluatedAt;
  final VocabularyType vocabularyType;
  final Vocabulary? vocabulary;

  const Flashcard({
    required this.id,
    required this.userVocabularyId,
    required this.status,
    required this.currentStageIndex,
    required this.stageLabel,
    required this.hasRegressed,
    required this.createdAt,
    required this.updatedAt,
    this.nextReviewAt,
    this.stagesHistory = const [],
    this.lastEvaluatedAt,
    this.vocabularyType = VocabularyType.system,
    this.vocabulary,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final vocabularyJson = json['vocabulary'];

    return Flashcard(
      id: json['id'] as String,
      userVocabularyId: json['user_vocabulary_id'] as String,
      status: FlashcardStatus.fromValue(json['status'] as String?),
      currentStageIndex: json['current_stage_index'] as int,
      stageLabel:
          json['stage_label'] as String? ?? 'D+${json['current_stage_index']}',
      nextReviewAt: json['next_review_at'] == null
          ? null
          : DateTime.parse(json['next_review_at'] as String),
      hasRegressed: json['has_regressed'] as bool? ?? false,
      stagesHistory: (json['stages_history'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                FlashcardStageHistory.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastEvaluatedAt: json['last_evaluated_at'] == null
          ? null
          : DateTime.parse(json['last_evaluated_at'] as String),
      vocabularyType: json['vocabulary_type'] == 'custom'
          ? VocabularyType.custom
          : VocabularyType.system,
      vocabulary: vocabularyJson is Map<String, dynamic>
          ? Vocabulary.fromJson(vocabularyJson)
          : null,
    );
  }

  bool get isCompleted => status == FlashcardStatus.completed;
  bool get isArchived => status == FlashcardStatus.archived;
  bool get hasHistory => currentStageIndex > 0 || lastEvaluatedAt != null;

  Flashcard copyWith({
    FlashcardStatus? status,
    int? currentStageIndex,
    String? stageLabel,
    DateTime? Function()? nextReviewAt,
    bool? hasRegressed,
  }) {
    return Flashcard(
      id: id,
      userVocabularyId: userVocabularyId,
      status: status ?? this.status,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      stageLabel: stageLabel ?? this.stageLabel,
      nextReviewAt: nextReviewAt != null ? nextReviewAt() : this.nextReviewAt,
      hasRegressed: hasRegressed ?? this.hasRegressed,
      stagesHistory: stagesHistory,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastEvaluatedAt: lastEvaluatedAt,
      vocabularyType: vocabularyType,
      vocabulary: vocabulary,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userVocabularyId,
    status,
    currentStageIndex,
    stageLabel,
    nextReviewAt,
    hasRegressed,
    stagesHistory,
    createdAt,
    updatedAt,
    lastEvaluatedAt,
    vocabularyType,
    vocabulary,
  ];
}
