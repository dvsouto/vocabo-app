import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_app/src/data/local_store.dart';
import 'package:vocabo_app/src/l10n/locale_providers.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/sync/connectivity.dart';
import 'package:vocabo_app/src/sync/sync_engine.dart';

List<UserVocabulary> _decodeAll(List<Map<String, dynamic>> rows) {
  final items = <UserVocabulary>[];
  for (final row in rows) {
    try {
      items.add(UserVocabulary.fromJson(row));
    } catch (e, st) {
      appLogger.handle(e, st, 'Skipping unreadable library row');
    }
  }
  return items;
}

/// The library as stored on this device. Before the first sync it waits
/// for the snapshot, or fails with [OfflineUnavailableException] offline.
Stream<List<UserVocabulary>> _watchLibrary(Ref ref) async* {
  final store = ref.watch(localStoreProvider);
  final online = ref.watch(isOnlineProvider);
  final seq = await store.read(SyncKeys.seq);
  if (seq == null) {
    if (!online) throw const OfflineUnavailableException();
    await store.watch(SyncKeys.seq).firstWhere((value) => value != null);
  }
  yield* store.watchUserVocabularies().map(_decodeAll);
}

/// Read-only view for the menu bar panel and spotlight.
final cachedUserVocabularyProvider = StreamProvider<List<UserVocabulary>>(
  _watchLibrary,
);

/// The library: read from the local database, written through the API when
/// it is reachable and queued in the outbox when it is not.
class UserVocabularyListNotifier extends StreamNotifier<List<UserVocabulary>> {
  /// Everything is local, so there is never another page to load.
  bool get hasMore => false;

  @override
  Stream<List<UserVocabulary>> build() => _watchLibrary(ref);

  Future<void> loadMore() async {}

  /// Adds a word with the body of `POST /user-vocabulary/add`.
  Future<void> addVocabulary(Map<String, dynamic> data) async {
    final store = ref.read(localStoreProvider);
    try {
      final created = await ref
          .read(apiClientProvider)
          .userVocabulary
          .add(data: data);
      ref.read(isOnlineProvider.notifier).reportOnline();
      await store.putUserVocabulary(created.toJson());
      unawaited(ref.read(syncEngineProvider.notifier).pull());
    } catch (e) {
      if (!isConnectionError(e)) rethrow;
      ref.read(isOnlineProvider.notifier).reportOffline();
      await _queueAdd(store, data);
    }
  }

  Future<void> _queueAdd(LocalStore store, Map<String, dynamic> data) async {
    final id = newLocalId();
    final flashcardId = newLocalId();
    final now = DateTime.now().toUtc();
    await store.putUserVocabulary({
      'id': id,
      'user_id': '',
      'vocabulary_type': 'system',
      'vocabulary_mongo_id': '',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'vocabulary': {
        '_id': '',
        'term': data['term'],
        'language': data['language'],
        'translation': data['translation'],
        'meaning': data['meaning'],
        'word_type': data['word_type'],
        'pronunciation': data['pronunciation'],
        'usage_examples': data['usage_examples'],
        'content_hash': data['content_hash'],
      },
    }, pending: true);
    await store.enqueue('vocabulary.add', {
      ...data,
      'user_vocabulary_id': id,
      'flashcard_id': flashcardId,
    });
    ref.read(syncEngineProvider.notifier).scheduleFlush();
  }

  /// Saves a word typed while offline; the API translates it when the
  /// outbox is flushed and the placeholder is replaced by the real entry.
  Future<void> addTermOffline(String term, String language) async {
    final store = ref.read(localStoreProvider);
    final id = newLocalId();
    final now = DateTime.now().toUtc().toIso8601String();
    await store.putUserVocabulary({
      'id': id,
      'user_id': '',
      'vocabulary_type': 'system',
      'vocabulary_mongo_id': '',
      'created_at': now,
      'updated_at': now,
      'vocabulary': {
        '_id': '',
        'term': term,
        'language': language,
        'meaning': ref.read(appLocalizationsProvider).wordAwaitingTranslation,
        'word_type': 'noun',
        'usage_examples': <String>[],
      },
    }, pending: true);
    await store.enqueue('vocabulary.add_term', {
      'user_vocabulary_id': id,
      'flashcard_id': newLocalId(),
      'term': term,
      'source_lang': language,
    });
    ref.read(syncEngineProvider.notifier).scheduleFlush();
  }

  /// Removes the word and its flashcard from the library.
  Future<void> removeVocabulary(String id) async {
    final store = ref.read(localStoreProvider);
    await store.deleteUserVocabulary(id);
    try {
      await ref.read(apiClientProvider).userVocabulary.remove(id);
      ref.read(isOnlineProvider.notifier).reportOnline();
    } catch (e) {
      if (e is NotFoundException) return;
      if (!isConnectionError(e)) rethrow;
      ref.read(isOnlineProvider.notifier).reportOffline();
      await store.enqueue('vocabulary.remove', {'user_vocabulary_id': id});
      ref.read(syncEngineProvider.notifier).scheduleFlush();
    }
  }

  void refresh() => unawaited(ref.read(syncEngineProvider.notifier).syncNow());
}

final userVocabularyListProvider =
    StreamNotifierProvider<UserVocabularyListNotifier, List<UserVocabulary>>(
      UserVocabularyListNotifier.new,
    );

final recentUserVocabulariesProvider =
    Provider<AsyncValue<List<UserVocabulary>>>((ref) {
      return ref
          .watch(userVocabularyListProvider)
          .whenData((list) => list.take(5).toList());
    });

/// Streak and weekly figures, computed by the API (the last response is
/// served while offline).
final vocabularyStatsProvider = FutureProvider<VocabularyStats>((ref) async {
  ref.watch(
    userVocabularyListProvider.select((value) => value.valueOrNull?.length),
  );
  final api = ref.watch(apiClientProvider);
  return api.userVocabulary.getStats(
    timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
  );
});
