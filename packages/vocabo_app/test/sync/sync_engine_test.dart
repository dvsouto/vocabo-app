import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_app/src/data/local_database.dart';
import 'package:vocabo_app/src/data/local_store.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/sync/sync_engine.dart';

/// A tiny in-memory stand-in for the sync API.
class _FakeServer implements HttpClientAdapter {
  bool online = true;
  int seq = 0;
  final changes = <Map<String, dynamic>>[];
  final pushed = <Map<String, dynamic>>[];

  void addChange(String entity, String id, Map<String, dynamic>? data) {
    seq++;
    changes.add({
      'seq': seq,
      'entity': entity,
      'id': id,
      'op': data == null ? 'delete' : 'upsert',
      'data': data,
    });
  }

  ResponseBody _json(Object body) => ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!online) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    switch (options.path) {
      case '/user/profile':
        return _json({
          ...{
            'id': 'user-1',
            'name': 'Ana',
            'email': 'ana@example.com',
            'native_language': 'pt',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        });
      case '/sync/state':
        return _json({'seq': seq});
      case '/sync/snapshot':
        return _json({
          'seq': seq,
          'user_vocabularies': [],
          'flashcards': [],
          'user_collections': [],
          'translation_lookups': [],
        });
      case '/sync/pull':
        final since = int.parse('${options.queryParameters['since']}');
        return _json({
          'changes': [
            for (final change in changes)
              if ((change['seq'] as int) > since) change,
          ],
          'seq': seq,
          'has_more': false,
        });
      case '/sync/manifest':
        return _json({'collections': 'v1'});
      case '/sync/push':
        final body = options.data as Map<String, dynamic>;
        final ops = (body['ops'] as List).cast<Map<String, dynamic>>();
        pushed.addAll(ops);
        return _json({
          'results': [
            for (final op in ops) {'id': op['id'], 'status': 'applied'},
          ],
          'seq': seq,
        });
    }
    return ResponseBody.fromString('{}', 404);
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _word(String id, String term) => {
  'id': id,
  'user_id': 'user-1',
  'vocabulary_type': 'system',
  'vocabulary_mongo_id': 'm-$id',
  'created_at': '2026-10-01T10:00:00.000Z',
  'updated_at': '2026-10-01T10:00:00.000Z',
  'vocabulary': {'id': 'v-$id', 'term': term},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initLogger(verbose: false));

  late _FakeServer server;
  late ProviderContainer container;
  late LocalStore store;

  setUp(() {
    server = _FakeServer();
    final db = LocalDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(
          VocaboApiClient(
            baseUrl: 'http://api',
            tokenStorage: InMemoryTokenStorage(),
            httpClientAdapter: server,
          ),
        ),
      ],
    );
    store = container.read(localStoreProvider);
  });

  tearDown(() async {
    container.dispose();
  });

  test('first start loads the snapshot and records the cursor', () async {
    server.seq = 4;
    await container.read(syncEngineProvider.notifier).start();

    expect(await store.read(SyncKeys.seq), 4);
    expect(await store.read(SyncKeys.userId), 'user-1');
    expect(container.read(syncEngineProvider).lastSyncedAt, isNotNull);
  });

  test('pull applies other devices\' changes and deletions', () async {
    await container.read(syncEngineProvider.notifier).start();

    server.addChange('user_vocabulary', 'w1', _word('w1', 'cohort'));
    server.addChange('user_vocabulary', 'w2', _word('w2', 'colonel'));
    server.addChange('user_vocabulary', 'w1', null);
    await container.read(syncEngineProvider.notifier).pull();

    final words = await store.watchUserVocabularies().first;
    expect(words.map((w) => w['id']), ['w2']);
    expect(await store.read(SyncKeys.seq), 3);
  });

  test('writes wait offline and go out when the connection is back', () async {
    await container.read(syncEngineProvider.notifier).start();
    server.online = false;

    await store.enqueue('preferences.update', {'show_translations': false});
    await container.read(syncEngineProvider.notifier).flush();
    expect(server.pushed, isEmpty);
    expect((await store.pendingOps()).length, 1);

    server.online = true;
    await container.read(syncEngineProvider.notifier).syncNow();
    expect(server.pushed.single['type'], 'preferences.update');
    expect(await store.pendingOps(), isEmpty);
  });

  test(
    'a pull does not overwrite a word with an unsent local change',
    () async {
      await container.read(syncEngineProvider.notifier).start();
      server.online = false;
      await store.putUserVocabulary(_word('w1', 'local edit'));
      await store.enqueue('vocabulary.remove', {'user_vocabulary_id': 'w1'});

      server.online = true;
      server.addChange('user_vocabulary', 'w1', _word('w1', 'server copy'));
      await container.read(syncEngineProvider.notifier).pull();

      final word = await store.readUserVocabulary('w1');
      expect((word!['vocabulary'] as Map)['term'], 'local edit');
    },
  );

  test('another account signing in clears the device', () async {
    await store.write(SyncKeys.userId, 'someone-else');
    await store.putUserVocabulary(_word('old', 'theirs'));

    await container.read(syncEngineProvider.notifier).start();

    expect(await store.readUserVocabulary('old'), isNull);
    expect(await store.read(SyncKeys.userId), 'user-1');
  });
}
