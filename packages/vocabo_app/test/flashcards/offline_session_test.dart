import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_app/src/data/local_database.dart';
import 'package:vocabo_app/src/data/local_store.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/providers/audio_player_providers.dart';
import 'package:vocabo_app/src/services/audio_prefetch_service.dart';
import 'package:vocabo_app/src/providers/flashcard_providers.dart';

Map<String, dynamic> _card(String id, String term) => {
  'id': id,
  'user_vocabulary_id': 'w-$id',
  'deck': 'library',
  'status': 'active',
  'current_stage_index': 0,
  'stage_label': 'D+0',
  'next_review_at': '2026-01-01T00:00:00.000Z',
  'has_regressed': false,
  'stages_history': [],
  'created_at': '2026-01-01T00:00:00.000Z',
  'updated_at': '2026-01-01T00:00:00.000Z',
  'version': 1,
  'vocabulary': {
    '_id': 'v-$id',
    'term': term,
    'language': 'English',
    'word_type': 'noun',
  },
};

class _NoPrefetch implements AudioPrefetchService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initLogger(verbose: false));

  late ProviderContainer container;
  late LocalStore store;

  setUp(() async {
    container = ProviderContainer(
      overrides: [
        audioPrefetchServiceProvider.overrideWithValue(_NoPrefetch()),
        localDatabaseProvider.overrideWithValue(
          LocalDatabase(NativeDatabase.memory()),
        ),
        apiClientProvider.overrideWithValue(
          VocaboApiClient(
            baseUrl: 'http://127.0.0.1:9',
            tokenStorage: InMemoryTokenStorage(),
          ),
        ),
      ],
    );
    store = container.read(localStoreProvider);
    await store.putFlashcard(_card('a', 'cohort'));
    await store.putFlashcard(_card('b', 'colonel'));
  });

  tearDown(() => container.dispose());

  test('a session runs from the local cards and queues the answers', () async {
    final notifier = container.read(flashcardSessionProvider.notifier);
    await notifier.startSession();
    var state = container.read(flashcardSessionProvider);
    expect(state.totalCards, 2);

    notifier.flip();
    await notifier.evaluate(FlashcardEvaluation.easy);
    state = container.read(flashcardSessionProvider);
    expect(state.evaluatedCount, 1);

    final first = state.session!.cards.first.flashcard;
    final saved = await store.readFlashcard(first.id);
    expect(saved!['version'], 2);
    expect(saved['current_stage_index'], 1);

    notifier.flip();
    await notifier.evaluate(FlashcardEvaluation.hard);
    expect(
      container.read(flashcardSessionProvider).phase,
      FlashcardsPhase.completion,
    );

    final ops = await store.pendingOps();
    expect(ops.map((op) => op.type), [
      'flashcard.evaluate',
      'flashcard.evaluate',
      'session.complete',
    ]);
  });
}
