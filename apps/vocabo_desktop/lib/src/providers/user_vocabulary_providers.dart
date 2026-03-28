import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/services/user_vocabulary_cache_service.dart';

final userVocabularyCacheServiceProvider =
    Provider<UserVocabularyCacheService>((ref) => UserVocabularyCacheService());

final cachedUserVocabularyProvider =
    FutureProvider<List<UserVocabulary>>((ref) async {
  final cacheService = ref.watch(userVocabularyCacheServiceProvider);
  final items = await cacheService.load();
  return items ?? [];
});

class UserVocabularyListNotifier extends AsyncNotifier<List<UserVocabulary>> {
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<UserVocabulary>> build() async {
    try {
      final api = ref.watch(apiClientProvider);
      final response = await api.userVocabulary.getAll(limit: 20);

      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;

      appLogger.debug('UserVocabularyList: loaded ${response.items.length} items, hasMore: $_hasMore');

      _saveToCache(response.items);

      return response.items;
    } catch (e, st) {
      appLogger.handle(e, st, 'UserVocabularyList build() error');
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    _isLoadingMore = true;

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.userVocabulary.getAll(
        cursor: _nextCursor,
        limit: 20,
      );

      _nextCursor = response.nextCursor;
      _hasMore = response.hasMore;

      final current = state.valueOrNull ?? [];
      state = AsyncData([...current, ...response.items]);
    } catch (e, st) {
      // Keep existing data, just report the error
      state = AsyncError(e, st);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> addVocabulary(Map<String, dynamic> data) async {
    final api = ref.read(apiClientProvider);
    final newEntry = await api.userVocabulary.add(data: data);

    final current = state.valueOrNull ?? [];
    final updated = [newEntry, ...current];
    state = AsyncData(updated);

    _saveToCache(updated);
  }

  void refresh() {
    _nextCursor = null;
    _hasMore = false;
    ref.invalidateSelf();
  }

  void _saveToCache(List<UserVocabulary> items) {
    final cacheService = ref.read(userVocabularyCacheServiceProvider);
    final toCache = items.take(100).toList();
    cacheService.save(toCache);
  }
}

final userVocabularyListProvider =
    AsyncNotifierProvider<UserVocabularyListNotifier, List<UserVocabulary>>(
  UserVocabularyListNotifier.new,
);

final recentUserVocabulariesProvider =
    Provider<AsyncValue<List<UserVocabulary>>>((ref) {
  return ref.watch(userVocabularyListProvider).whenData(
        (list) => list.take(5).toList(),
      );
});
