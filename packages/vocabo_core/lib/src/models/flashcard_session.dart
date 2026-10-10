import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/enums/flashcard_evaluation.dart';
import 'package:vocabo_core/src/enums/flashcard_status.dart';
import 'package:vocabo_core/src/models/flashcard.dart';

class FlashcardSessionCard extends Equatable {
  final String id;
  final int position;
  final FlashcardEvaluation? evaluation;
  final DateTime? evaluatedAt;
  final Flashcard flashcard;

  const FlashcardSessionCard({
    required this.id,
    required this.position,
    required this.flashcard,
    this.evaluation,
    this.evaluatedAt,
  });

  factory FlashcardSessionCard.fromJson(Map<String, dynamic> json) {
    return FlashcardSessionCard(
      id: json['id'] as String,
      position: json['position'] as int,
      evaluation: FlashcardEvaluation.fromValue(json['evaluation'] as String?),
      evaluatedAt: json['evaluated_at'] == null
          ? null
          : DateTime.parse(json['evaluated_at'] as String),
      flashcard: Flashcard.fromJson(json['flashcard'] as Map<String, dynamic>),
    );
  }

  bool get isEvaluated => evaluation != null;

  FlashcardSessionCard copyWith({
    FlashcardEvaluation? Function()? evaluation,
    DateTime? Function()? evaluatedAt,
    Flashcard? flashcard,
  }) {
    return FlashcardSessionCard(
      id: id,
      position: position,
      evaluation: evaluation != null ? evaluation() : this.evaluation,
      evaluatedAt: evaluatedAt != null ? evaluatedAt() : this.evaluatedAt,
      flashcard: flashcard ?? this.flashcard,
    );
  }

  @override
  List<Object?> get props => [id, position, evaluation, evaluatedAt, flashcard];
}

/// A review session. While [id] is null the deck only lives in memory and is
/// persisted by the API on the first evaluation.
class FlashcardSession extends Equatable {
  final String? id;
  final FlashcardSessionStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> flashcardIds;
  final List<FlashcardSessionCard> cards;

  const FlashcardSession({
    required this.id,
    required this.status,
    required this.cards,
    this.startedAt,
    this.completedAt,
    this.flashcardIds = const [],
  });

  factory FlashcardSession.fromJson(Map<String, dynamic> json) {
    return FlashcardSession(
      id: json['id'] as String?,
      status: FlashcardSessionStatus.fromValue(json['status'] as String?),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      flashcardIds: (json['flashcard_ids'] as List<dynamic>? ?? const [])
          .map((id) => id as String)
          .toList(growable: false),
      cards: (json['cards'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                FlashcardSessionCard.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  bool get isVirtual => id == null;
  bool get isEmpty => cards.isEmpty;

  int get evaluatedCount => cards.where((card) => card.isEvaluated).length;

  bool get isComplete => cards.isNotEmpty && evaluatedCount == cards.length;

  /// Index of the first card still waiting for an evaluation, or -1.
  int get firstPendingIndex => cards.indexWhere((card) => !card.isEvaluated);

  FlashcardSession copyWith({
    List<FlashcardSessionCard>? cards,
    List<String>? flashcardIds,
  }) {
    return FlashcardSession(
      id: id,
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      cards: cards ?? this.cards,
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    startedAt,
    completedAt,
    flashcardIds,
    cards,
  ];
}

class FlashcardEvaluationResult extends Equatable {
  final Flashcard flashcard;
  final int? stageAtEvaluation;
  final int? newStage;
  final bool sessionCompleted;
  final FlashcardSession? session;

  const FlashcardEvaluationResult({
    required this.flashcard,
    required this.sessionCompleted,
    this.stageAtEvaluation,
    this.newStage,
    this.session,
  });

  factory FlashcardEvaluationResult.fromJson(Map<String, dynamic> json) {
    return FlashcardEvaluationResult(
      flashcard: Flashcard.fromJson(json['flashcard'] as Map<String, dynamic>),
      stageAtEvaluation: json['stage_at_evaluation'] as int?,
      newStage: json['new_stage'] as int?,
      sessionCompleted: json['session_completed'] as bool? ?? false,
      session: json['session'] == null
          ? null
          : FlashcardSession.fromJson(json['session'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [
    flashcard,
    stageAtEvaluation,
    newStage,
    sessionCompleted,
    session,
  ];
}
