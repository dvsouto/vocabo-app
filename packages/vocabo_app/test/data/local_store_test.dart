import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_app/src/data/local_database.dart';
import 'package:vocabo_app/src/data/local_store.dart';

Map<String, dynamic> _word(String id, String term, DateTime createdAt) => {
  'id': id,
  'user_id': 'u1',
  'vocabulary_type': 'system',
  'vocabulary_mongo_id': 'm-$id',
  'created_at': createdAt.toIso8601String(),
  'updated_at': createdAt.toIso8601String(),
  'vocabulary': {'id': 'v-$id', 'term': term},
};

void main() {
  late LocalStore store;

  setUp(() {
    store = LocalStore(LocalDatabase(NativeDatabase.memory()));
  });

  tearDown(() => store.db.close());

  test('library is listed newest first', () async {
    await store.putUserVocabulary(_word('a', 'old', DateTime.utc(2026, 1, 1)));
    await store.putUserVocabulary(_word('b', 'new', DateTime.utc(2026, 2, 1)));

    final rows = await store.watchUserVocabularies().first;
    expect(rows.map((row) => row['id']), ['b', 'a']);
  });

  test('outbox keeps writes in order until removed', () async {
    final first = await store.enqueue('vocabulary.remove', {
      'user_vocabulary_id': 'a',
    });
    await store.enqueue('preferences.update', {'show_translations': false});

    final ops = await store.pendingOps();
    expect(ops.map((op) => op.type), [
      'vocabulary.remove',
      'preferences.update',
    ]);
    expect(await store.watchPendingCount().first, 2);

    await store.markOpFailed(first, 'offline');
    expect((await store.pendingOps()).first.attempts, 1);

    await store.removeOp(first);
    expect(await store.watchPendingCount().first, 1);
  });

  test('a local word adopts the id the server already had', () async {
    await store.putUserVocabulary(
      _word('local', 'cohort', DateTime.utc(2026, 3, 1)),
      pending: true,
    );
    await store.enqueue('flashcard.evaluate', {
      'flashcard_id': 'f',
      'user_vocabulary_id': 'local',
    });

    await store.rekeyUserVocabulary('local', 'server');

    expect(await store.readUserVocabulary('local'), isNull);
    final op = (await store.pendingOps()).single;
    expect(op.payload, contains('server'));
    expect(op.payload, isNot(contains('local')));
  });

  test('documents round-trip and clearAll forgets the account', () async {
    await store.write('profile', {'name': 'Ana'});
    expect(await store.read('profile'), {'name': 'Ana'});

    await store.putFlashcard({
      'id': 'f1',
      'deck': 'library',
      'status': 'active',
      'next_review_at': '2026-03-01T00:00:00.000Z',
      'version': 3,
    });
    expect((await store.readFlashcard('f1'))?['version'], 3);

    await store.clearAll();
    expect(await store.read('profile'), isNull);
    expect(await store.readFlashcards(), isEmpty);
  });
}
