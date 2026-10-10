import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

Map<String, dynamic> cardJson({
  required String id,
  required int position,
  String? evaluation,
}) {
  return {
    'id': id,
    'position': position,
    'evaluation': evaluation,
    'evaluated_at': evaluation == null ? null : '2026-10-10T05:31:32.946Z',
    'flashcard': {
      'id': 'fc-$id',
      'user_vocabulary_id': 'uv-$id',
      'status': 'active',
      'current_stage_index': 0,
      'stage_label': 'D+0',
      'next_review_at': '2026-10-10T05:31:32.946Z',
      'has_regressed': false,
      'stages_history': [
        {
          'stage_index': 0,
          'interval_days': 0,
          'should_be_at': '2026-10-10',
          'date_at': null,
          'completed_at': null,
          'days_late': 0,
        },
      ],
      'created_at': '2026-10-10T05:00:00.000Z',
      'updated_at': '2026-10-10T05:00:00.000Z',
      'vocabulary_type': 'custom',
      'vocabulary': {
        '_id': 'mongo-$id',
        'term': 'potato',
        'language': 'English',
        'translation': 'batata',
        'meaning': 'A starchy root vegetable.',
        'word_type': 'noun',
        'usage_examples': ['I like potato.'],
      },
    },
  };
}

void main() {
  test('parses a virtual session and exposes pending cards', () {
    final session = FlashcardSession.fromJson({
      'id': null,
      'status': 'in_progress',
      'started_at': null,
      'completed_at': null,
      'flashcard_ids': ['fc-a', 'fc-b'],
      'cards': [cardJson(id: 'a', position: 0), cardJson(id: 'b', position: 1)],
    });

    expect(session.isVirtual, isTrue);
    expect(session.flashcardIds, ['fc-a', 'fc-b']);
    expect(session.cards.first.flashcard.vocabulary?.term, 'potato');
    expect(session.cards.first.flashcard.vocabularyType, VocabularyType.custom);
    expect(session.firstPendingIndex, 0);
    expect(session.isComplete, isFalse);
  });

  test('resumes a persisted session at the first pending card', () {
    final session = FlashcardSession.fromJson({
      'id': 'session-1',
      'status': 'in_progress',
      'cards': [
        cardJson(id: 'a', position: 0, evaluation: 'easy'),
        cardJson(id: 'b', position: 1),
      ],
    });

    expect(session.isVirtual, isFalse);
    expect(session.evaluatedCount, 1);
    expect(session.firstPendingIndex, 1);
    expect(session.cards.first.evaluation, FlashcardEvaluation.easy);
  });

  test('parses the status summary states', () {
    final waiting = FlashcardStatusSummary.fromJson({
      'total_active': 3,
      'due_count': 0,
      'completed_count': 0,
      'archived_count': 1,
      'has_active_session': false,
      'next_review_at': '2026-10-11T05:31:32.946Z',
    });

    expect(waiting.isWaiting, isTrue);
    expect(waiting.canStartSession, isFalse);

    final resumable = FlashcardStatusSummary.fromJson({
      'total_active': 3,
      'due_count': 0,
      'has_active_session': true,
      'next_review_at': null,
    });

    expect(resumable.canStartSession, isTrue);
    expect(resumable.isWaiting, isFalse);
  });
}
