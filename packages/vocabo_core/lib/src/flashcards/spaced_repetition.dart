import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/enums/flashcard_evaluation.dart';
import 'package:vocabo_core/src/enums/flashcard_status.dart';
import 'package:vocabo_core/src/flashcards/flashcard_stages.dart';
import 'package:vocabo_core/src/models/flashcard.dart';

const int _dayMs = 24 * 60 * 60 * 1000;

/// The scheduling fields of a flashcard. Mirrors `SpacedRepetitionState` in
/// the API (`src/lib/spaced-repetition.ts`). Dates are always UTC.
class SpacedRepetitionState extends Equatable {
  final int currentStageIndex;
  final DateTime? nextReviewAt;
  final bool hasRegressed;
  final FlashcardStatus status;
  final List<FlashcardStageHistory> stagesHistory;

  const SpacedRepetitionState({
    required this.currentStageIndex,
    required this.nextReviewAt,
    required this.hasRegressed,
    required this.status,
    required this.stagesHistory,
  });

  factory SpacedRepetitionState.fromFlashcard(Flashcard card) =>
      SpacedRepetitionState(
        currentStageIndex: card.currentStageIndex,
        nextReviewAt: card.nextReviewAt?.toUtc(),
        hasRegressed: card.hasRegressed,
        status: card.status,
        stagesHistory: card.stagesHistory,
      );

  SpacedRepetitionState copyWith({
    int? currentStageIndex,
    DateTime? Function()? nextReviewAt,
    bool? hasRegressed,
    FlashcardStatus? status,
    List<FlashcardStageHistory>? stagesHistory,
  }) => SpacedRepetitionState(
    currentStageIndex: currentStageIndex ?? this.currentStageIndex,
    nextReviewAt: nextReviewAt != null ? nextReviewAt() : this.nextReviewAt,
    hasRegressed: hasRegressed ?? this.hasRegressed,
    status: status ?? this.status,
    stagesHistory: stagesHistory ?? this.stagesHistory,
  );

  @override
  List<Object?> get props => [
    currentStageIndex,
    nextReviewAt,
    hasRegressed,
    status,
    stagesHistory,
  ];
}

/// Converts [date] to UTC with millisecond precision, the precision of a JS
/// `Date`, so results match the API to the millisecond.
DateTime toUtcMillis(DateTime date) => DateTime.fromMillisecondsSinceEpoch(
  date.millisecondsSinceEpoch,
  isUtc: true,
);

/// The UTC calendar day of [date] as `YYYY-MM-DD`.
String toDateKey(DateTime date) {
  final utc = date.toUtc();
  final year = utc.year.toString().padLeft(4, '0');
  final month = utc.month.toString().padLeft(2, '0');
  final day = utc.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Adds exact 24 hour blocks, like the API (not calendar days).
DateTime addDays(DateTime date, int days) =>
    DateTime.fromMillisecondsSinceEpoch(
      date.millisecondsSinceEpoch + days * _dayMs,
      isUtc: true,
    );

int _daysLate(String shouldBeAt, DateTime studiedAt) {
  final expected = DateTime.tryParse('${shouldBeAt}T00:00:00.000Z');
  if (expected == null) return 0;
  final late =
      ((studiedAt.millisecondsSinceEpoch - expected.millisecondsSinceEpoch) /
              _dayMs)
          .floor();
  return late < 0 ? 0 : late;
}

List<FlashcardStageHistory> buildInitialStagesHistory(
  DateTime now, [
  List<int> stages = flashcardStages,
]) => [
  for (var index = 0; index < stages.length; index++)
    FlashcardStageHistory(
      stageIndex: index,
      intervalDays: stages[index],
      shouldBeAt: index == 0 ? toDateKey(now) : null,
    ),
];

SpacedRepetitionState buildInitialState(
  DateTime now, [
  List<int> stages = flashcardStages,
]) => SpacedRepetitionState(
  currentStageIndex: 0,
  nextReviewAt: toUtcMillis(now),
  hasRegressed: false,
  status: FlashcardStatus.active,
  stagesHistory: buildInitialStagesHistory(now, stages),
);

/// Marks the studied stage with the actual date and lateness, then projects
/// the expected date of the stage the card moves to from that real date, so
/// delays push every future stage forward.
///
/// [projectionStageIndex] and [projectionDaysUntil] go together; pass neither
/// when the card leaves the ladder.
List<FlashcardStageHistory> updateStagesHistory(
  List<FlashcardStageHistory> history,
  int studiedStageIndex,
  DateTime now, {
  int? projectionStageIndex,
  int projectionDaysUntil = 0,
}) {
  final at = toUtcMillis(now);
  final updated = [...history];

  final studied = updated.indexWhere(
    (entry) => entry.stageIndex == studiedStageIndex,
  );
  if (studied != -1) {
    final entry = updated[studied];
    final shouldBeAt = entry.shouldBeAt;
    updated[studied] = FlashcardStageHistory(
      stageIndex: entry.stageIndex,
      intervalDays: entry.intervalDays,
      shouldBeAt: shouldBeAt,
      dateAt: toDateKey(at),
      completedAt: at,
      daysLate: shouldBeAt != null && shouldBeAt.isNotEmpty
          ? _daysLate(shouldBeAt, at)
          : entry.daysLate,
    );
  }

  if (projectionStageIndex != null) {
    final target = updated.indexWhere(
      (entry) => entry.stageIndex == projectionStageIndex,
    );
    if (target != -1) {
      final entry = updated[target];
      updated[target] = FlashcardStageHistory(
        stageIndex: entry.stageIndex,
        intervalDays: entry.intervalDays,
        shouldBeAt: toDateKey(addDays(at, projectionDaysUntil)),
        dateAt: entry.dateAt,
        completedAt: entry.completedAt,
        daysLate: entry.daysLate,
      );
    }
  }

  return List.unmodifiable(updated);
}

SpacedRepetitionState _applyHard(SpacedRepetitionState state, DateTime now) {
  final newIndex = state.hasRegressed
      ? state.currentStageIndex
      : previousStageIndex(state.currentStageIndex);

  return state.copyWith(
    currentStageIndex: newIndex,
    nextReviewAt: () => now,
    hasRegressed: true,
    stagesHistory: updateStagesHistory(
      state.stagesHistory,
      state.currentStageIndex,
      now,
      projectionStageIndex: newIndex,
      projectionDaysUntil: 0,
    ),
  );
}

SpacedRepetitionState _applyMedium(SpacedRepetitionState state, DateTime now) {
  return state.copyWith(
    nextReviewAt: () => addDays(now, 1),
    hasRegressed: false,
    stagesHistory: updateStagesHistory(
      state.stagesHistory,
      state.currentStageIndex,
      now,
      projectionStageIndex: state.currentStageIndex,
      projectionDaysUntil: 1,
    ),
  );
}

SpacedRepetitionState _applyEasy(
  SpacedRepetitionState state,
  DateTime now,
  List<int> stages,
) {
  if (isLastStage(state.currentStageIndex, stages)) {
    return state.copyWith(
      status: FlashcardStatus.completed,
      nextReviewAt: () => null,
      hasRegressed: false,
      stagesHistory: updateStagesHistory(
        state.stagesHistory,
        state.currentStageIndex,
        now,
      ),
    );
  }

  final nextIndex = nextStageIndex(state.currentStageIndex, stages)!;
  final daysUntil =
      stageInterval(nextIndex, stages) -
      stageInterval(state.currentStageIndex, stages);

  return state.copyWith(
    currentStageIndex: nextIndex,
    nextReviewAt: () => addDays(now, daysUntil),
    hasRegressed: false,
    stagesHistory: updateStagesHistory(
      state.stagesHistory,
      state.currentStageIndex,
      now,
      projectionStageIndex: nextIndex,
      projectionDaysUntil: daysUntil,
    ),
  );
}

/// Moves the card through the ladder exactly like the API: hard regresses
/// one stage (once in a row) and is due now, medium keeps the stage and is
/// due in a day, easy advances (or completes the card at the last stage).
SpacedRepetitionState applyEvaluation(
  SpacedRepetitionState state,
  FlashcardEvaluation evaluation,
  DateTime now, [
  List<int> stages = flashcardStages,
]) {
  final at = toUtcMillis(now);
  return switch (evaluation) {
    FlashcardEvaluation.hard => _applyHard(state, at),
    FlashcardEvaluation.medium => _applyMedium(state, at),
    FlashcardEvaluation.easy => _applyEasy(state, at, stages),
  };
}

/// Returns [card] with [state] applied, the way the API persists and
/// serializes an evaluation: stage label and direction are derived from the
/// new stage, `updated_at` and `last_evaluated_at` become [now].
Flashcard applyStateToFlashcard(
  Flashcard card,
  SpacedRepetitionState state, {
  required DateTime now,
  List<int> stages = flashcardStages,
  List<int> reverseIntervals = defaultReverseStageIntervals,
}) {
  final at = toUtcMillis(now);
  return Flashcard(
    id: card.id,
    userVocabularyId: card.userVocabularyId,
    deck: card.deck,
    collectionItem: card.collectionItem,
    status: state.status,
    currentStageIndex: state.currentStageIndex,
    stageLabel: flashcardStageLabel(state.currentStageIndex, stages),
    direction: stageDirection(
      state.currentStageIndex,
      stages: stages,
      reverseIntervals: reverseIntervals,
    ),
    nextReviewAt: state.nextReviewAt,
    hasRegressed: state.hasRegressed,
    stagesHistory: state.stagesHistory,
    createdAt: card.createdAt,
    updatedAt: at,
    lastEvaluatedAt: at,
    vocabularyType: card.vocabularyType,
    vocabulary: card.vocabulary,
  );
}

/// JSON shape of a stage history entry as the API stores it.
Map<String, dynamic> stageHistoryToJson(FlashcardStageHistory entry) => {
  'stage_index': entry.stageIndex,
  'interval_days': entry.intervalDays,
  'should_be_at': entry.shouldBeAt,
  'date_at': entry.dateAt,
  'completed_at': entry.completedAt == null
      ? null
      : toUtcMillis(entry.completedAt!).toIso8601String(),
  'days_late': entry.daysLate,
};
