import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/enums/flashcard_evaluation.dart';
import 'package:vocabo_core/src/enums/flashcard_status.dart';
import 'package:vocabo_core/src/flashcards/flashcard_stages.dart';
import 'package:vocabo_core/src/flashcards/spaced_repetition.dart';

/// Rank used by the offline conflict rule: the lower, the more cautious
/// (hard < medium < easy).
int evaluationCaution(FlashcardEvaluation evaluation) => switch (evaluation) {
  FlashcardEvaluation.hard => 0,
  FlashcardEvaluation.medium => 1,
  FlashcardEvaluation.easy => 2,
};

bool isMoreCautious(FlashcardEvaluation evaluation, FlashcardEvaluation than) =>
    evaluationCaution(evaluation) < evaluationCaution(than);

/// Clamps a client `evaluated_at` to `[createdAt, serverNow]`.
DateTime clampEvaluatedAt(
  DateTime evaluatedAt, {
  DateTime? createdAt,
  DateTime? serverNow,
}) {
  var at = evaluatedAt;
  if (createdAt != null && at.isBefore(createdAt)) at = createdAt;
  if (serverNow != null && at.isAfter(serverNow)) at = serverNow;
  return toUtcMillis(at);
}

/// The review (from the evaluation log) that produced a card version.
class RecordedEvaluation extends Equatable {
  final FlashcardEvaluation evaluation;

  /// State of the card right before this review was applied.
  final SpacedRepetitionState stateBefore;
  final int resultingVersion;

  const RecordedEvaluation({
    required this.evaluation,
    required this.stateBefore,
    required this.resultingVersion,
  });

  @override
  List<Object?> get props => [evaluation, stateBefore, resultingVersion];
}

enum EvaluationResolution {
  /// `base_version` matched: applied normally.
  applied,

  /// Conflict where the incoming review is more cautious: re-applied from
  /// the state before the review that produced the current version.
  reapplied,

  /// Conflict where the incoming review is not more cautious: the current
  /// state stays and the review is only recorded.
  kept,

  /// The card is archived: the review is only recorded.
  archived,
}

class EvaluationMergeResult extends Equatable {
  final EvaluationResolution resolution;
  final SpacedRepetitionState state;
  final int version;

  /// Snapshot to log as `state_before` for this review.
  final SpacedRepetitionState stateBefore;

  /// The effective (clamped) evaluation time.
  final DateTime evaluatedAt;

  const EvaluationMergeResult({
    required this.resolution,
    required this.state,
    required this.version,
    required this.stateBefore,
    required this.evaluatedAt,
  });

  /// Whether the review changed the card (the log's `applied` column).
  bool get applied =>
      resolution == EvaluationResolution.applied ||
      resolution == EvaluationResolution.reapplied;

  @override
  List<Object?> get props => [
    resolution,
    state,
    version,
    stateBefore,
    evaluatedAt,
  ];
}

/// Decides the outcome of a `flashcard.evaluate` op (sync contract §3).
///
/// - Archived card: recorded only, nothing changes.
/// - `baseVersion == currentVersion` (or newer): apply normally, version + 1.
/// - `baseVersion < currentVersion`: both reviews count as one and the more
///   cautious wins. When [evaluation] is more cautious than
///   [lastEvaluation] (the review whose `resultingVersion` is
///   [currentVersion]), it is re-applied from `lastEvaluation.stateBefore`,
///   version + 1; otherwise the current state is kept. When the current
///   version was not produced by a review (archive, restore, release) or the
///   log entry is unknown, the current state is kept.
///
/// [evaluatedAt] is clamped to `[createdAt, serverNow]` when given and used
/// as "now" for the spaced repetition.
EvaluationMergeResult resolveFlashcardEvaluation({
  required SpacedRepetitionState current,
  required int currentVersion,
  required FlashcardEvaluation evaluation,
  required int baseVersion,
  required DateTime evaluatedAt,
  RecordedEvaluation? lastEvaluation,
  DateTime? createdAt,
  DateTime? serverNow,
  List<int> stages = flashcardStages,
}) {
  final at = clampEvaluatedAt(
    evaluatedAt,
    createdAt: createdAt,
    serverNow: serverNow,
  );

  EvaluationMergeResult unchanged(EvaluationResolution resolution) =>
      EvaluationMergeResult(
        resolution: resolution,
        state: current,
        version: currentVersion,
        stateBefore: current,
        evaluatedAt: at,
      );

  if (current.status == FlashcardStatus.archived) {
    return unchanged(EvaluationResolution.archived);
  }

  if (baseVersion >= currentVersion) {
    return EvaluationMergeResult(
      resolution: EvaluationResolution.applied,
      state: applyEvaluation(current, evaluation, at, stages),
      version: currentVersion + 1,
      stateBefore: current,
      evaluatedAt: at,
    );
  }

  final producedCurrent =
      lastEvaluation != null &&
      lastEvaluation.resultingVersion == currentVersion;
  if (!producedCurrent ||
      !isMoreCautious(evaluation, lastEvaluation.evaluation)) {
    return unchanged(EvaluationResolution.kept);
  }

  final previous = lastEvaluation.stateBefore;
  return EvaluationMergeResult(
    resolution: EvaluationResolution.reapplied,
    state: applyEvaluation(previous, evaluation, at, stages),
    version: currentVersion + 1,
    stateBefore: previous,
    evaluatedAt: at,
  );
}
