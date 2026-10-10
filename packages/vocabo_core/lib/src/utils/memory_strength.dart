import 'package:vocabo_core/src/enums/flashcard_evaluation.dart';
import 'package:vocabo_core/src/enums/flashcard_status.dart';

/// Human readable strength of a word in memory, derived from its spaced
/// repetition stage. Shown as a name plus a row of [totalLevels] dots.
class MemoryStrength {
  static const stageNames = [
    'New',
    'Fresh',
    'Familiar',
    'Settling',
    'Anchored',
    'Deep',
    'Lasting',
  ];
  static const masteredName = 'Mastered';
  static const archivedName = 'Archived';
  static const totalLevels = 7;

  final String name;

  /// Number of filled dots, from 0 (new) to [totalLevels] (mastered).
  final int level;

  const MemoryStrength._(this.name, this.level);

  factory MemoryStrength.of({
    required int stageIndex,
    FlashcardStatus status = FlashcardStatus.active,
  }) {
    final index = stageIndex.clamp(0, stageNames.length - 1);
    return switch (status) {
      FlashcardStatus.completed => const MemoryStrength._(
        masteredName,
        totalLevels,
      ),
      FlashcardStatus.archived => MemoryStrength._(archivedName, index),
      FlashcardStatus.active => MemoryStrength._(stageNames[index], index),
    };
  }

  bool get isMastered => level == totalLevels;
}

/// When the card comes back after the given answer, phrased for a button
/// caption ("today", "tomorrow", "in 2 days", "mastered").
String describeNextReview(
  FlashcardEvaluation evaluation, {
  required int stageIndex,
  required List<int> stages,
}) {
  switch (evaluation) {
    case FlashcardEvaluation.hard:
      return 'today';
    case FlashcardEvaluation.medium:
      return 'tomorrow';
    case FlashcardEvaluation.easy:
      if (stageIndex >= stages.length - 1) return 'mastered';
      final days = stages[stageIndex + 1] - stages[stageIndex];
      return days == 1 ? 'tomorrow' : 'in $days days';
  }
}
