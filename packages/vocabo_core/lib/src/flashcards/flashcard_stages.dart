import 'package:vocabo_core/src/enums/flashcard_evaluation.dart';
import 'package:vocabo_core/src/models/flashcard_status_summary.dart';

/// Spaced repetition stages expressed in days since the card was added.
/// The interval between two consecutive stages is the difference of their
/// values.
const List<int> flashcardStages = [0, 1, 3, 5, 7, 14, 28];

const int defaultCardsPerSession = 15;

const double defaultBandAPercent = 0.2;
const double defaultBandBPercent = 0.4;
const double defaultBandCPercent = 0.4;

/// Stage interval (days) → share of band B.
const Map<int, double> defaultBandBDistribution = {
  1: 1 / 3,
  3: 1 / 3,
  5: 1 / 6,
  7: 1 / 6,
};

/// Stage interval (days) → share of band C.
const Map<int, double> defaultBandCDistribution = {14: 0.5, 28: 0.5};

/// Stage intervals (days) at which the card is shown in reverse.
const List<int> defaultReverseStageIntervals = [7, 28];

/// Order in which stages receive leftover deck positions.
const List<int> defaultRedistributionPriority = [1, 3, 5, 7, 14, 28, 0];

/// Groups a stage the same way the deck bands do (A, B and C).
enum StageBand {
  newCard('new'),
  returning('returning'),
  longTerm('long_term');

  const StageBand(this.value);
  final String value;
}

/// Everything the deck composition needs. Mirrors `FlashcardDeckConfig` in
/// the API (`src/config/flashcards.ts`).
class FlashcardDeckConfig {
  final List<int> stages;
  final int cardsPerSession;
  final double bandAPercent;
  final double bandBPercent;
  final double bandCPercent;
  final Map<int, double> bandBDistribution;
  final Map<int, double> bandCDistribution;
  final List<int> redistributionPriority;

  const FlashcardDeckConfig({
    this.stages = flashcardStages,
    this.cardsPerSession = defaultCardsPerSession,
    this.bandAPercent = defaultBandAPercent,
    this.bandBPercent = defaultBandBPercent,
    this.bandCPercent = defaultBandCPercent,
    this.bandBDistribution = defaultBandBDistribution,
    this.bandCDistribution = defaultBandCDistribution,
    this.redistributionPriority = defaultRedistributionPriority,
  });

  static const defaults = FlashcardDeckConfig();

  /// Uses the stages and session size served by `GET /flashcards/config`,
  /// keeping the band rules (which the API does not expose) at their defaults.
  factory FlashcardDeckConfig.fromConfig(FlashcardConfig config, {int? size}) =>
      FlashcardDeckConfig(
        stages: config.stages,
        cardsPerSession: size ?? config.cardsPerSession,
      );

  FlashcardDeckConfig copyWith({List<int>? stages, int? cardsPerSession}) =>
      FlashcardDeckConfig(
        stages: stages ?? this.stages,
        cardsPerSession: cardsPerSession ?? this.cardsPerSession,
        bandAPercent: bandAPercent,
        bandBPercent: bandBPercent,
        bandCPercent: bandCPercent,
        bandBDistribution: bandBDistribution,
        bandCDistribution: bandCDistribution,
        redistributionPriority: redistributionPriority,
      );
}

/// Interval in days of [stageIndex]; 0 when the index is out of range.
int stageInterval(int stageIndex, [List<int> stages = flashcardStages]) =>
    stageIndex >= 0 && stageIndex < stages.length ? stages[stageIndex] : 0;

int? nextStageIndex(int currentIndex, [List<int> stages = flashcardStages]) {
  final next = currentIndex + 1;
  return next < stages.length ? next : null;
}

int previousStageIndex(int currentIndex) =>
    currentIndex - 1 < 0 ? 0 : currentIndex - 1;

bool isLastStage(int stageIndex, [List<int> stages = flashcardStages]) =>
    stageIndex == stages.length - 1;

int? stageIndexByInterval(int interval, [List<int> stages = flashcardStages]) {
  final index = stages.indexOf(interval);
  return index == -1 ? null : index;
}

/// Pass the `reverse_stage_intervals` from `GET /flashcards/config` as
/// [reverseIntervals]: it is empty for accounts without reverse cards.
FlashcardDirection stageDirection(
  int stageIndex, {
  List<int> stages = flashcardStages,
  List<int> reverseIntervals = defaultReverseStageIntervals,
}) => reverseIntervals.contains(stageInterval(stageIndex, stages))
    ? FlashcardDirection.reverse
    : FlashcardDirection.forward;

StageBand stageBand(
  int stageIndex, {
  List<int> stages = flashcardStages,
  Map<int, double> longTermDistribution = defaultBandCDistribution,
}) {
  final interval = stageInterval(stageIndex, stages);
  if (interval == 0) return StageBand.newCard;
  if (longTermDistribution.containsKey(interval)) return StageBand.longTerm;
  return StageBand.returning;
}

/// Label such as `D+7`; falls back to the index when it is out of range.
String flashcardStageLabel(
  int stageIndex, [
  List<int> stages = flashcardStages,
]) {
  final inRange = stageIndex >= 0 && stageIndex < stages.length;
  return 'D+${inRange ? stages[stageIndex] : stageIndex}';
}
