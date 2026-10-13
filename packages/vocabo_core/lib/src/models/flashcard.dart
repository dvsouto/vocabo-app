import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/enums/flashcard_deck.dart';
import 'package:vocabo_core/src/enums/flashcard_evaluation.dart';
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

/// The collection word behind a card of the collections deck.
class FlashcardCollectionItem extends Equatable {
  final String id;
  final String term;
  final String collectionId;
  final String collectionTitle;

  const FlashcardCollectionItem({
    required this.id,
    required this.term,
    required this.collectionId,
    required this.collectionTitle,
  });

  factory FlashcardCollectionItem.fromJson(Map<String, dynamic> json) =>
      FlashcardCollectionItem(
        id: json['id'] as String,
        term: json['term'] as String,
        collectionId: json['collection_id'] as String? ?? '',
        collectionTitle: json['collection_title'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, term, collectionId, collectionTitle];
}

class Flashcard extends Equatable {
  final String id;

  /// Null for cards of the collections deck.
  final String? userVocabularyId;
  final FlashcardDeck deck;
  final FlashcardCollectionItem? collectionItem;
  final FlashcardStatus status;
  final int currentStageIndex;
  final String stageLabel;
  final FlashcardDirection direction;
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
    this.userVocabularyId,
    this.deck = FlashcardDeck.library,
    this.collectionItem,
    required this.status,
    required this.currentStageIndex,
    required this.stageLabel,
    required this.hasRegressed,
    required this.createdAt,
    required this.updatedAt,
    this.direction = FlashcardDirection.forward,
    this.nextReviewAt,
    this.stagesHistory = const [],
    this.lastEvaluatedAt,
    this.vocabularyType = VocabularyType.system,
    this.vocabulary,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    final vocabularyJson = json['vocabulary'];
    final itemJson = json['collection_item'];

    return Flashcard(
      id: json['id'] as String,
      userVocabularyId: json['user_vocabulary_id'] as String?,
      deck: FlashcardDeck.fromValue(json['deck'] as String?),
      collectionItem: itemJson is Map<String, dynamic>
          ? FlashcardCollectionItem.fromJson(itemJson)
          : null,
      status: FlashcardStatus.fromValue(json['status'] as String?),
      currentStageIndex: json['current_stage_index'] as int,
      stageLabel:
          json['stage_label'] as String? ?? 'D+${json['current_stage_index']}',
      direction: FlashcardDirection.fromValue(json['direction'] as String?),
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

  /// The English term, also before a collection word is translated.
  String get term => vocabulary?.term ?? collectionItem?.term ?? '';

  Flashcard copyWith({
    Vocabulary? Function()? vocabulary,
    FlashcardStatus? status,
    int? currentStageIndex,
    String? stageLabel,
    DateTime? Function()? nextReviewAt,
    bool? hasRegressed,
  }) {
    return Flashcard(
      id: id,
      userVocabularyId: userVocabularyId,
      deck: deck,
      collectionItem: collectionItem,
      status: status ?? this.status,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      stageLabel: stageLabel ?? this.stageLabel,
      direction: direction,
      nextReviewAt: nextReviewAt != null ? nextReviewAt() : this.nextReviewAt,
      hasRegressed: hasRegressed ?? this.hasRegressed,
      stagesHistory: stagesHistory,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastEvaluatedAt: lastEvaluatedAt,
      vocabularyType: vocabularyType,
      vocabulary: vocabulary != null ? vocabulary() : this.vocabulary,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userVocabularyId,
    deck,
    collectionItem,
    status,
    currentStageIndex,
    stageLabel,
    direction,
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
