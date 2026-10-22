import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

final _created = DateTime.utc(2026, 3, 1, 9);
final _first = DateTime.utc(2026, 3, 10, 10);
final _second = DateTime.utc(2026, 3, 10, 18);

SpacedRepetitionState _stage(int index) =>
    buildInitialState(_created).copyWith(currentStageIndex: index);

/// Another device already reviewed [before] with [evaluation] at [_first],
/// producing version 6 from version 5.
({SpacedRepetitionState current, RecordedEvaluation last}) _reviewedElsewhere(
  SpacedRepetitionState before,
  FlashcardEvaluation evaluation,
) => (
  current: applyEvaluation(before, evaluation, _first),
  last: RecordedEvaluation(
    evaluation: evaluation,
    stateBefore: before,
    resultingVersion: 6,
  ),
);

void main() {
  group('evaluation caution', () {
    test('orders hard < medium < easy', () {
      expect(
        isMoreCautious(FlashcardEvaluation.hard, FlashcardEvaluation.medium),
        isTrue,
      );
      expect(
        isMoreCautious(FlashcardEvaluation.medium, FlashcardEvaluation.easy),
        isTrue,
      );
      expect(
        isMoreCautious(FlashcardEvaluation.easy, FlashcardEvaluation.hard),
        isFalse,
      );
      expect(
        isMoreCautious(FlashcardEvaluation.medium, FlashcardEvaluation.medium),
        isFalse,
      );
    });
  });

  group('resolveFlashcardEvaluation', () {
    test('applies normally and bumps the version when versions match', () {
      final current = _stage(3);
      final result = resolveFlashcardEvaluation(
        current: current,
        currentVersion: 5,
        evaluation: FlashcardEvaluation.easy,
        baseVersion: 5,
        evaluatedAt: _first,
      );

      expect(result.resolution, EvaluationResolution.applied);
      expect(result.applied, isTrue);
      expect(result.version, 6);
      expect(result.stateBefore, current);
      expect(
        result.state,
        applyEvaluation(current, FlashcardEvaluation.easy, _first),
      );
    });

    test('only records the review on an archived card', () {
      final current = _stage(2).copyWith(status: FlashcardStatus.archived);
      for (final base in [3, 4]) {
        final result = resolveFlashcardEvaluation(
          current: current,
          currentVersion: 4,
          evaluation: FlashcardEvaluation.hard,
          baseVersion: base,
          evaluatedAt: _first,
        );

        expect(result.resolution, EvaluationResolution.archived);
        expect(result.applied, isFalse);
        expect(result.state, current);
        expect(result.version, 4);
      }
    });

    test('re-applies a more cautious review from the previous state', () {
      final before = _stage(3);
      final other = _reviewedElsewhere(before, FlashcardEvaluation.easy);

      final result = resolveFlashcardEvaluation(
        current: other.current,
        currentVersion: 6,
        evaluation: FlashcardEvaluation.hard,
        baseVersion: 5,
        evaluatedAt: _second,
        lastEvaluation: other.last,
      );

      expect(result.resolution, EvaluationResolution.reapplied);
      expect(result.applied, isTrue);
      expect(result.version, 7);
      expect(result.stateBefore, before);
      expect(result.state.currentStageIndex, 2);
      expect(result.state.hasRegressed, isTrue);
      expect(result.state.nextReviewAt, _second);
      expect(
        result.state,
        applyEvaluation(before, FlashcardEvaluation.hard, _second),
      );
    });

    test('medium beats an easy review from another device', () {
      final before = _stage(4);
      final other = _reviewedElsewhere(before, FlashcardEvaluation.easy);

      final result = resolveFlashcardEvaluation(
        current: other.current,
        currentVersion: 6,
        evaluation: FlashcardEvaluation.medium,
        baseVersion: 5,
        evaluatedAt: _second,
        lastEvaluation: other.last,
      );

      expect(result.resolution, EvaluationResolution.reapplied);
      expect(result.state.currentStageIndex, 4);
      expect(result.state.nextReviewAt, DateTime.utc(2026, 3, 11, 18));
    });

    test(
      'keeps the current state when the incoming review is less cautious',
      () {
        final other = _reviewedElsewhere(_stage(3), FlashcardEvaluation.hard);

        final result = resolveFlashcardEvaluation(
          current: other.current,
          currentVersion: 6,
          evaluation: FlashcardEvaluation.easy,
          baseVersion: 5,
          evaluatedAt: _second,
          lastEvaluation: other.last,
        );

        expect(result.resolution, EvaluationResolution.kept);
        expect(result.applied, isFalse);
        expect(result.state, other.current);
        expect(result.version, 6);
      },
    );

    test('keeps the current state when both reviews are equally cautious', () {
      final other = _reviewedElsewhere(_stage(3), FlashcardEvaluation.medium);

      final result = resolveFlashcardEvaluation(
        current: other.current,
        currentVersion: 6,
        evaluation: FlashcardEvaluation.medium,
        baseVersion: 5,
        evaluatedAt: _second,
        lastEvaluation: other.last,
      );

      expect(result.resolution, EvaluationResolution.kept);
      expect(result.state, other.current);
    });

    test('keeps the state when the current version was not a review', () {
      final other = _reviewedElsewhere(_stage(3), FlashcardEvaluation.easy);

      // The card was restored after that review (version 7).
      final restored = resolveFlashcardEvaluation(
        current: other.current,
        currentVersion: 7,
        evaluation: FlashcardEvaluation.hard,
        baseVersion: 5,
        evaluatedAt: _second,
        lastEvaluation: other.last,
      );
      final unknown = resolveFlashcardEvaluation(
        current: other.current,
        currentVersion: 6,
        evaluation: FlashcardEvaluation.hard,
        baseVersion: 5,
        evaluatedAt: _second,
      );

      expect(restored.resolution, EvaluationResolution.kept);
      expect(restored.version, 7);
      expect(unknown.resolution, EvaluationResolution.kept);
    });

    test('applies normally when the base version is ahead', () {
      final result = resolveFlashcardEvaluation(
        current: _stage(1),
        currentVersion: 2,
        evaluation: FlashcardEvaluation.medium,
        baseVersion: 3,
        evaluatedAt: _first,
      );

      expect(result.resolution, EvaluationResolution.applied);
      expect(result.version, 3);
    });

    test('clamps evaluated_at to the card creation and server now', () {
      final serverNow = DateTime.utc(2026, 3, 10, 12);

      final future = resolveFlashcardEvaluation(
        current: _stage(0),
        currentVersion: 1,
        evaluation: FlashcardEvaluation.medium,
        baseVersion: 1,
        evaluatedAt: DateTime.utc(2026, 3, 12),
        createdAt: _created,
        serverNow: serverNow,
      );
      final past = resolveFlashcardEvaluation(
        current: _stage(0),
        currentVersion: 1,
        evaluation: FlashcardEvaluation.hard,
        baseVersion: 1,
        evaluatedAt: DateTime.utc(2026, 2, 1),
        createdAt: _created,
        serverNow: serverNow,
      );

      expect(future.evaluatedAt, serverNow);
      expect(future.state.nextReviewAt, DateTime.utc(2026, 3, 11, 12));
      expect(past.evaluatedAt, _created);
      expect(past.state.nextReviewAt, _created);
      expect(past.state.stagesHistory[0].dateAt, '2026-03-01');
    });

    test('uses the UTC day of a local evaluated_at', () {
      final localLateNight = DateTime.parse('2026-03-10T22:30:00-03:00');

      final result = resolveFlashcardEvaluation(
        current: buildInitialState(_created),
        currentVersion: 1,
        evaluation: FlashcardEvaluation.easy,
        baseVersion: 1,
        evaluatedAt: localLateNight,
      );

      expect(result.evaluatedAt, DateTime.utc(2026, 3, 11, 1, 30));
      expect(result.state.stagesHistory[0].dateAt, '2026-03-11');
      expect(result.state.stagesHistory[1].shouldBeAt, '2026-03-12');
      expect(result.state.stagesHistory[0].daysLate, 10);
    });
  });
}
