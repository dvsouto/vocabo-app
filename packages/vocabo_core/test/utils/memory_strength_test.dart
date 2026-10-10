import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  const stages = [0, 1, 3, 5, 7, 14, 28];

  group('MemoryStrength', () {
    test('names every active stage and fills dots as it grows', () {
      final names = [
        for (var i = 0; i < stages.length; i++)
          MemoryStrength.of(stageIndex: i).name,
      ];

      expect(names, MemoryStrength.stageNames);
      expect(MemoryStrength.of(stageIndex: 0).level, 0);
      expect(MemoryStrength.of(stageIndex: 3).level, 3);
    });

    test('completed cards are mastered with every dot filled', () {
      final strength = MemoryStrength.of(
        stageIndex: 6,
        status: FlashcardStatus.completed,
      );

      expect(strength.name, 'Mastered');
      expect(strength.level, MemoryStrength.totalLevels);
      expect(strength.isMastered, isTrue);
    });

    test('clamps unexpected stage indexes', () {
      expect(MemoryStrength.of(stageIndex: 42).name, 'Lasting');
      expect(MemoryStrength.of(stageIndex: -1).name, 'New');
    });
  });

  group('describeNextReview', () {
    String describe(FlashcardEvaluation evaluation, int stageIndex) =>
        describeNextReview(evaluation, stageIndex: stageIndex, stages: stages);

    test('blank comes back today and fuzzy tomorrow', () {
      expect(describe(FlashcardEvaluation.hard, 3), 'today');
      expect(describe(FlashcardEvaluation.medium, 3), 'tomorrow');
    });

    test('clear follows the gap to the next stage', () {
      expect(describe(FlashcardEvaluation.easy, 0), 'tomorrow');
      expect(describe(FlashcardEvaluation.easy, 1), 'in 2 days');
      expect(describe(FlashcardEvaluation.easy, 5), 'in 14 days');
    });

    test('clear on the last stage masters the word', () {
      expect(describe(FlashcardEvaluation.easy, 6), 'mastered');
    });
  });

  group('DailyReminderSchedule', () {
    final morning = DateTime(2026, 10, 10, 8, 30);

    test('fires once the reminder time has passed', () {
      expect(
        DailyReminderSchedule.shouldNotify(
          enabled: true,
          time: '08:00',
          now: morning,
        ),
        isTrue,
      );
    });

    test('waits until the reminder time', () {
      expect(
        DailyReminderSchedule.shouldNotify(
          enabled: true,
          time: '09:00',
          now: morning,
        ),
        isFalse,
      );
    });

    test('fires at most once per day', () {
      expect(
        DailyReminderSchedule.shouldNotify(
          enabled: true,
          time: '08:00',
          now: morning,
          lastNotifiedOn: DateTime(2026, 10, 10, 8, 1),
        ),
        isFalse,
      );
      expect(
        DailyReminderSchedule.shouldNotify(
          enabled: true,
          time: '08:00',
          now: morning,
          lastNotifiedOn: DateTime(2026, 10, 9, 8, 1),
        ),
        isTrue,
      );
    });

    test('never fires when disabled or misconfigured', () {
      expect(
        DailyReminderSchedule.shouldNotify(
          enabled: false,
          time: '08:00',
          now: morning,
        ),
        isFalse,
      );
      expect(
        DailyReminderSchedule.shouldNotify(
          enabled: true,
          time: '8am',
          now: morning,
        ),
        isFalse,
      );
    });
  });

  test('status summary estimates the next session length', () {
    const summary = FlashcardStatusSummary(
      totalActive: 40,
      dueCount: 30,
      completedCount: 0,
      archivedCount: 0,
      hasActiveSession: false,
    );

    expect(summary.estimatedMinutes(), 5);
  });

  test('library entries carry their flashcard summary', () {
    final entry = UserVocabulary.fromJson({
      'id': 'uv-1',
      'user_id': 'u-1',
      'vocabulary_type': 'system',
      'vocabulary_mongo_id': 'm-1',
      'created_at': '2026-10-10T05:00:00.000Z',
      'updated_at': '2026-10-10T05:00:00.000Z',
      'flashcard': {
        'id': 'fc-1',
        'status': 'active',
        'current_stage_index': 2,
        'next_review_at': '2026-10-12T05:00:00.000Z',
      },
    });

    expect(entry.flashcard?.strength.name, 'Familiar');
    expect(UserVocabulary.fromJson(entry.toJson()).flashcard, entry.flashcard);
  });
}
