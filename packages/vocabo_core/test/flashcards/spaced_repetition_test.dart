import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

const _dayMs = 24 * 60 * 60 * 1000;
final _start = DateTime.utc(2026, 3, 10, 10);

DateTime _plus(DateTime date, int ms) => DateTime.fromMillisecondsSinceEpoch(
  date.millisecondsSinceEpoch + ms,
  isUtc: true,
);

SpacedRepetitionState _atStage(int index, [DateTime? now]) =>
    buildInitialState(now ?? _start).copyWith(currentStageIndex: index);

void main() {
  group('buildInitialState', () {
    test('starts at D+0 due immediately with one history entry per stage', () {
      final state = buildInitialState(_start);

      expect(state.currentStageIndex, 0);
      expect(state.nextReviewAt, _start);
      expect(state.status, FlashcardStatus.active);
      expect(state.stagesHistory, hasLength(flashcardStages.length));
      expect(state.stagesHistory[0].shouldBeAt, '2026-03-10');
      expect(state.stagesHistory[1].shouldBeAt, isNull);
    });
  });

  group('applyEvaluation — easy', () {
    test('advances one stage and schedules by the interval difference', () {
      final next = applyEvaluation(
        _atStage(3),
        FlashcardEvaluation.easy,
        _start,
      );

      expect(next.currentStageIndex, 4);
      expect(next.nextReviewAt, _plus(_start, 2 * _dayMs));
      expect(next.hasRegressed, isFalse);
    });

    test('uses the 7 and 14 day gaps at the end of the ladder', () {
      final fromD7 = applyEvaluation(
        _atStage(4),
        FlashcardEvaluation.easy,
        _start,
      );
      expect(fromD7.nextReviewAt, _plus(_start, 7 * _dayMs));

      final fromD14 = applyEvaluation(
        _atStage(5),
        FlashcardEvaluation.easy,
        _start,
      );
      expect(fromD14.nextReviewAt, _plus(_start, 14 * _dayMs));
    });

    test('completes the card at the last stage', () {
      final next = applyEvaluation(
        _atStage(flashcardStages.length - 1),
        FlashcardEvaluation.easy,
        _start,
      );

      expect(next.status, FlashcardStatus.completed);
      expect(next.nextReviewAt, isNull);
      expect(next.currentStageIndex, flashcardStages.length - 1);
    });

    test('clears a previous regression', () {
      final regressed = _atStage(2).copyWith(hasRegressed: true);
      expect(
        applyEvaluation(
          regressed,
          FlashcardEvaluation.easy,
          _start,
        ).hasRegressed,
        isFalse,
      );
    });
  });

  group('applyEvaluation — medium', () {
    test('keeps the stage and returns the next day', () {
      final next = applyEvaluation(
        _atStage(2),
        FlashcardEvaluation.medium,
        _start,
      );

      expect(next.currentStageIndex, 2);
      expect(next.nextReviewAt, _plus(_start, _dayMs));
      expect(next.hasRegressed, isFalse);
    });
  });

  group('applyEvaluation — hard', () {
    test('regresses one stage and becomes due immediately', () {
      final next = applyEvaluation(
        _atStage(4),
        FlashcardEvaluation.hard,
        _start,
      );

      expect(next.currentStageIndex, 3);
      expect(next.nextReviewAt, _start);
      expect(next.hasRegressed, isTrue);
    });

    test('does not regress twice in a row', () {
      final once = applyEvaluation(
        _atStage(4),
        FlashcardEvaluation.hard,
        _start,
      );
      final twice = applyEvaluation(once, FlashcardEvaluation.hard, _start);

      expect(twice.currentStageIndex, 3);
      expect(twice.hasRegressed, isTrue);
    });

    test('never goes below D+0', () {
      final next = applyEvaluation(
        _atStage(0),
        FlashcardEvaluation.hard,
        _start,
      );
      expect(next.currentStageIndex, 0);
    });
  });

  group('stages history projection', () {
    test('records the study date and projects the next stage from it', () {
      final next = applyEvaluation(
        buildInitialState(_start),
        FlashcardEvaluation.easy,
        _start,
      );
      final d0 = next.stagesHistory[0];
      final d1 = next.stagesHistory[1];

      expect(d0.dateAt, toDateKey(_start));
      expect(d0.daysLate, 0);
      expect(d1.shouldBeAt, '2026-03-11');
    });

    test('pushes future dates forward when the user is late', () {
      final afterFirst = applyEvaluation(
        buildInitialState(_start),
        FlashcardEvaluation.easy,
        _start,
      );

      final lateStudy = DateTime.parse('2026-03-24T09:00:00.000Z');
      final afterSecond = applyEvaluation(
        afterFirst,
        FlashcardEvaluation.easy,
        lateStudy,
      );
      final d1 = afterSecond.stagesHistory[1];
      final d3 = afterSecond.stagesHistory[2];

      expect(d1.dateAt, '2026-03-24');
      expect(d1.daysLate, 13);
      expect(d3.shouldBeAt, '2026-03-26');
    });

    test('counts a same-day study as on time', () {
      final afterFirst = applyEvaluation(
        buildInitialState(_start),
        FlashcardEvaluation.easy,
        _start,
      );
      final onTime = DateTime.parse('2026-03-11T23:30:00.000Z');
      final afterSecond = applyEvaluation(
        afterFirst,
        FlashcardEvaluation.easy,
        onTime,
      );

      expect(afterSecond.stagesHistory[1].daysLate, 0);
    });

    test('stores the completion instant in UTC with millisecond precision', () {
      final now = DateTime.utc(2026, 3, 10, 10, 0, 0, 123, 456);
      final next = applyEvaluation(
        buildInitialState(_start),
        FlashcardEvaluation.easy,
        now,
      );

      final completedAt = next.stagesHistory[0].completedAt!;
      expect(completedAt.isUtc, isTrue);
      expect(completedAt, DateTime.utc(2026, 3, 10, 10, 0, 0, 123));
      expect(
        stageHistoryToJson(next.stagesHistory[0])['completed_at'],
        '2026-03-10T10:00:00.123Z',
      );
    });

    test('medium projects the same stage to the next day', () {
      final next = applyEvaluation(
        buildInitialState(_start),
        FlashcardEvaluation.medium,
        _start,
      );

      expect(next.stagesHistory[0].dateAt, '2026-03-10');
      expect(next.stagesHistory[0].shouldBeAt, '2026-03-11');
    });

    test('hard at D+0 keeps the stage due today', () {
      final next = applyEvaluation(
        buildInitialState(_start),
        FlashcardEvaluation.hard,
        _start,
      );

      expect(next.stagesHistory[0].shouldBeAt, '2026-03-10');
      expect(next.stagesHistory[0].daysLate, 0);
    });

    test('keeps days late when the studied stage had no expected date', () {
      final state = _atStage(3);
      final next = applyEvaluation(state, FlashcardEvaluation.easy, _start);

      expect(next.stagesHistory[3].daysLate, 0);
      expect(next.stagesHistory[3].dateAt, '2026-03-10');
    });
  });

  group('UTC and day boundaries', () {
    test('date keys use the UTC day, not the local one', () {
      final lateNightInBrazil = DateTime.parse('2026-03-10T23:30:00-03:00');

      expect(toDateKey(lateNightInBrazil), '2026-03-11');
    });

    test('converts local now values to UTC', () {
      final local = DateTime.utc(2026, 3, 10, 10).toLocal();
      final next = applyEvaluation(
        buildInitialState(local),
        FlashcardEvaluation.medium,
        local,
      );

      expect(next.nextReviewAt!.isUtc, isTrue);
      expect(next.nextReviewAt, DateTime.utc(2026, 3, 11, 10));
    });

    test('a study one millisecond before UTC midnight is still on time', () {
      final afterFirst = applyEvaluation(
        buildInitialState(_start),
        FlashcardEvaluation.easy,
        _start,
      );
      final lastMs = DateTime.parse('2026-03-11T23:59:59.999Z');
      final firstMs = DateTime.parse('2026-03-12T00:00:00.000Z');

      expect(
        applyEvaluation(
          afterFirst,
          FlashcardEvaluation.easy,
          lastMs,
        ).stagesHistory[1].daysLate,
        0,
      );
      final late = applyEvaluation(
        afterFirst,
        FlashcardEvaluation.easy,
        firstMs,
      );
      expect(late.stagesHistory[1].daysLate, 1);
      expect(late.stagesHistory[1].dateAt, '2026-03-12');
    });

    test('a study before the expected day is never negative', () {
      final afterFirst = applyEvaluation(
        buildInitialState(_start),
        FlashcardEvaluation.easy,
        _start,
      );
      final early = applyEvaluation(
        afterFirst,
        FlashcardEvaluation.easy,
        DateTime.parse('2026-03-10T22:00:00.000Z'),
      );

      expect(early.stagesHistory[1].daysLate, 0);
    });

    test('adds exact 24 hour blocks across a DST change', () {
      final now = DateTime.parse('2026-03-08T06:30:00.000Z');
      final next = applyEvaluation(_atStage(5), FlashcardEvaluation.easy, now);

      expect(next.nextReviewAt, DateTime.parse('2026-03-22T06:30:00.000Z'));
      expect(next.stagesHistory[6].shouldBeAt, '2026-03-22');
    });

    test('projection near midnight lands on the next UTC day', () {
      final now = DateTime.parse('2026-03-10T23:59:00.000Z');
      final next = applyEvaluation(
        buildInitialState(now),
        FlashcardEvaluation.easy,
        now,
      );

      expect(next.stagesHistory[0].dateAt, '2026-03-10');
      expect(next.stagesHistory[1].shouldBeAt, '2026-03-11');
    });
  });

  group('stage helpers', () {
    test('shows reverse cards only at the configured intervals', () {
      final directions = [
        for (var i = 0; i < flashcardStages.length; i++) stageDirection(i),
      ];

      expect(directions, [
        FlashcardDirection.forward,
        FlashcardDirection.forward,
        FlashcardDirection.forward,
        FlashcardDirection.forward,
        FlashcardDirection.reverse,
        FlashcardDirection.forward,
        FlashcardDirection.reverse,
      ]);
    });

    test('free accounts never get reverse cards', () {
      expect(
        stageDirection(4, reverseIntervals: const []),
        FlashcardDirection.forward,
      );
    });

    test('groups stages like the deck bands', () {
      final bands = [
        for (var i = 0; i < flashcardStages.length; i++) stageBand(i),
      ];

      expect(bands, [
        StageBand.newCard,
        StageBand.returning,
        StageBand.returning,
        StageBand.returning,
        StageBand.returning,
        StageBand.longTerm,
        StageBand.longTerm,
      ]);
    });

    test('labels stages by interval', () {
      expect(flashcardStageLabel(0), 'D+0');
      expect(flashcardStageLabel(4), 'D+7');
      expect(flashcardStageLabel(9), 'D+9');
    });
  });

  group('applyStateToFlashcard', () {
    test('derives label and direction and stamps the evaluation time', () {
      final card = Flashcard(
        id: 'c1',
        status: FlashcardStatus.active,
        currentStageIndex: 3,
        stageLabel: 'D+5',
        hasRegressed: false,
        createdAt: DateTime.utc(2026, 3, 1),
        updatedAt: DateTime.utc(2026, 3, 1),
        stagesHistory: buildInitialStagesHistory(DateTime.utc(2026, 3, 1)),
      );
      final state = applyEvaluation(
        SpacedRepetitionState.fromFlashcard(card),
        FlashcardEvaluation.easy,
        _start,
      );
      final updated = applyStateToFlashcard(card, state, now: _start);

      expect(updated.currentStageIndex, 4);
      expect(updated.stageLabel, 'D+7');
      expect(updated.direction, FlashcardDirection.reverse);
      expect(updated.updatedAt, _start);
      expect(updated.lastEvaluatedAt, _start);
      expect(updated.stagesHistory, state.stagesHistory);
    });
  });
}
