import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';

import 'package:vocabo_app/src/data/local_store.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/sync/connectivity.dart';

/// Keys of the documents the sync engine keeps in the local store.
abstract final class SyncKeys {
  static const seq = 'sync.seq';
  static const lastSyncedAt = 'sync.last_synced_at';
  static const manifest = 'sync.manifest';
  static const preferences = 'preferences';
  static const profile = 'profile';
  static const userCollections = 'user_collections';
  static const userId = 'sync.user_id';
}

class SyncStatus {
  const SyncStatus({
    this.downloading = false,
    this.pending = 0,
    this.lastSyncedAt,
  });

  /// Pulling changes from the API right now (the indicator spins).
  final bool downloading;

  /// Writes waiting in the outbox.
  final int pending;
  final DateTime? lastSyncedAt;

  SyncStatus copyWith({
    bool? downloading,
    int? pending,
    DateTime? Function()? lastSyncedAt,
  }) => SyncStatus(
    downloading: downloading ?? this.downloading,
    pending: pending ?? this.pending,
    lastSyncedAt: lastSyncedAt != null ? lastSyncedAt() : this.lastSyncedAt,
  );
}

/// Whether this engine instance syncs. The desktop's menu bar panel and
/// spotlight run in separate engines and leave syncing to the main window.
final syncEnabledProvider = Provider<bool>((_) => true);

/// A queued write the API refused for good (e.g. a plan limit), for the UI
/// to explain.
final rejectedOpProvider = StateProvider<SyncOpResult?>((_) => null);

final manifestChangedProvider = StateProvider<Set<String>>((_) => const {});

/// Keeps this device and the API in step: flushes the outbox in batches,
/// pulls what other devices changed, and refreshes shared data when its
/// version moves. Cheap when idle: no timers run with an empty outbox
/// except the 5-minute pull while the app is in the foreground.
class SyncEngine extends Notifier<SyncStatus> {
  static const _batchSize = 50;
  static const _burstDelays = [
    Duration(seconds: 2),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];
  static const _restDelay = Duration(minutes: 5);
  static const _pullInterval = Duration(minutes: 5);

  Timer? _retryTimer;
  Timer? _pullTimer;
  Timer? _flushDebounce;
  int _failedAttempts = 0;
  bool _flushing = false;
  bool _pulling = false;
  bool _started = false;
  AppLifecycleListener? _lifecycle;

  /// False once the provider scope is disposed: work still in flight stops
  /// at its next step instead of touching a dead container.
  bool _alive = true;
  StreamSubscription<int>? _pendingSubscription;

  late LocalStore _store;
  late VocaboApiClient _client;
  SyncRepository get _api => _client.sync;

  @override
  SyncStatus build() {
    _store = ref.read(localStoreProvider);
    _client = ref.read(apiClientProvider);
    ref.onDispose(() {
      _alive = false;
      _stop();
    });
    ref.listen(isOnlineProvider, (was, online) {
      if (online && was == false) {
        _failedAttempts = 0;
        unawaited(syncNow());
      }
    });
    return const SyncStatus();
  }

  /// Starts syncing for the signed-in account (main engine only).
  Future<void> start() async {
    if (_started || !ref.read(syncEnabledProvider)) return;
    _started = true;
    await _forgetOtherAccount();

    final last = await _store.read(SyncKeys.lastSyncedAt);
    _setState(
      (s) => s.copyWith(
        lastSyncedAt: () => DateTime.tryParse(last as String? ?? ''),
      ),
    );
    _pendingSubscription = _store.watchPendingCount().listen((count) {
      _setState((s) => s.copyWith(pending: count));
    });
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _startPullTimer();
        unawaited(syncNow());
      },
      onPause: () => _pullTimer?.cancel(),
    );
    _startPullTimer();
    await syncNow();
  }

  /// The database belongs to the device, not the account: when a different
  /// account signs in, nothing of the previous one may show.
  Future<void> _forgetOtherAccount() async {
    try {
      final profile = await _client.user.getProfile();
      final saved = await _store.read(SyncKeys.userId);
      if (saved != null && saved != profile.id) await _store.clearAll();
      await _store.write(SyncKeys.userId, profile.id);
    } catch (e, st) {
      if (!isConnectionError(e)) appLogger.handle(e, st, 'Sync owner check');
    }
  }

  void _stop() {
    _retryTimer?.cancel();
    _pullTimer?.cancel();
    _flushDebounce?.cancel();
    _lifecycle?.dispose();
    _pendingSubscription?.cancel();
    _started = false;
  }

  void _reportOnline(bool online) {
    if (!_alive) return;
    final notifier = ref.read(isOnlineProvider.notifier);
    online ? notifier.reportOnline() : notifier.reportOffline();
  }

  void _setState(SyncStatus Function(SyncStatus current) update) {
    if (_alive) state = update(state);
  }

  void _startPullTimer() {
    _pullTimer?.cancel();
    _pullTimer = Timer.periodic(_pullInterval, (_) => unawaited(pull()));
  }

  /// Push, then pull, then the manifest.
  Future<void> syncNow() async {
    if (!_started || !_alive) return;
    await flush();
    await pull();
    await _checkManifest();
  }

  /// Called after a write is queued: flushes shortly after, batching
  /// writes made in quick succession.
  void scheduleFlush() {
    if (!_started) return;
    _flushDebounce?.cancel();
    _flushDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(flush());
    });
  }

  // --- Push ---

  Future<void> flush() async {
    if (_flushing || !_started) return;
    _flushing = true;
    try {
      while (_alive) {
        final ops = await _store.pendingOps(limit: _batchSize);
        if (ops.isEmpty) break;

        final SyncPushResponse response;
        try {
          response = await _api.push([
            for (final op in ops)
              SyncOp(
                id: op.id,
                type: op.type,
                payload: jsonDecode(op.payload) as Map<String, dynamic>,
                createdAt: op.createdAt,
              ),
          ]);
        } catch (e, st) {
          if (isConnectionError(e)) {
            _reportOnline(false);
          } else {
            appLogger.handle(e, st, 'Sync push failed');
          }
          _scheduleRetry();
          return;
        }

        if (!_alive) return;
        _reportOnline(true);
        _failedAttempts = 0;
        _retryTimer?.cancel();

        var keptAny = false;
        for (final result in response.results) {
          if (!_alive) return;
          final op = ops.firstWhere((o) => o.id == result.id);
          if (result.retryLater) {
            keptAny = true;
            await _store.markOpFailed(op.id, result.errorCode ?? 'retry');
            continue;
          }
          await _applyResult(op.type, op.payload, result);
          await _store.removeOp(op.id);
        }
        if (keptAny) {
          _scheduleRetry();
          return;
        }
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _applyResult(
    String type,
    String rawPayload,
    SyncOpResult result,
  ) async {
    final payload = jsonDecode(rawPayload) as Map<String, dynamic>;
    final data = result.data;

    if (type.startsWith('vocabulary.add')) {
      final localId = payload['user_vocabulary_id'] as String;
      if (result.status == SyncOpStatus.rejected) {
        await _store.deleteUserVocabulary(localId);
        if (_alive) ref.read(rejectedOpProvider.notifier).state = result;
        return;
      }
      if (data != null) {
        if (data['id'] != localId) {
          await _store.rekeyUserVocabulary(localId, data['id'] as String);
        }
        await _store.putUserVocabulary(data);
        final flashcard = data['flashcard'];
        if (flashcard is Map<String, dynamic> && flashcard['deck'] != null) {
          await _store.putFlashcard(flashcard);
        }
      }
      return;
    }

    if (result.status == SyncOpStatus.rejected) {
      appLogger.warning(
        'Sync op $type rejected: ${result.errorCode} ${result.errorMessage}',
      );
      if (_alive) ref.read(rejectedOpProvider.notifier).state = result;
      return;
    }
    if (data != null && type.startsWith('flashcard.')) {
      await _store.putFlashcard(data);
    }
  }

  /// Three quick attempts (2s, 10s, 30s), then one every 5 minutes for
  /// another three, and so on.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    final inBurst = _failedAttempts % (_burstDelays.length + 1);
    final delay = inBurst < _burstDelays.length
        ? _burstDelays[inBurst]
        : _restDelay;
    _failedAttempts++;
    _retryTimer = Timer(delay, () => unawaited(syncNow()));
  }

  // --- Pull ---

  Future<void> pull() async {
    if (_pulling || !_started) return;
    _pulling = true;
    try {
      final localSeq = (await _store.read(SyncKeys.seq) as num?)?.toInt();
      final int serverSeq;
      try {
        serverSeq = await _api.getSeq();
      } catch (e, st) {
        if (isConnectionError(e)) {
          _reportOnline(false);
        } else {
          appLogger.handle(e, st, 'Sync state failed');
        }
        return;
      }
      _reportOnline(true);
      if (localSeq != null && serverSeq <= localSeq) {
        await _markSynced();
        return;
      }

      _setState((s) => s.copyWith(downloading: true));
      if (localSeq == null) {
        await _applySnapshot(await _api.getSnapshot());
      } else {
        var since = localSeq;
        while (_alive) {
          final page = await _api.pull(since: since);
          final pendingIds = await _pendingEntityIds();
          for (final change in page.changes) {
            if (pendingIds.contains(change.id)) continue;
            await _applyChange(change);
          }
          since = page.seq;
          await _store.write(SyncKeys.seq, since);
          if (!page.hasMore) break;
        }
      }
      await _markSynced();
    } catch (e, st) {
      if (isConnectionError(e)) {
        _reportOnline(false);
      } else {
        appLogger.handle(e, st, 'Sync pull failed');
      }
    } finally {
      _pulling = false;
      _setState((s) => s.copyWith(downloading: false));
    }
  }

  Future<void> _markSynced() async {
    final now = DateTime.now();
    await _store.write(SyncKeys.lastSyncedAt, now.toIso8601String());
    _setState((s) => s.copyWith(lastSyncedAt: () => now));
  }

  /// Ids touched by writes still in the outbox: the local copy is newer
  /// than what the server returns, so pulls skip them until pushed.
  Future<Set<String>> _pendingEntityIds() async {
    final ids = <String>{};
    for (final op in await _store.pendingOps(limit: 1000)) {
      final payload = jsonDecode(op.payload) as Map<String, dynamic>;
      for (final entry in payload.entries) {
        if (entry.key == 'id' || entry.key.endsWith('_id')) {
          if (entry.value is String) ids.add(entry.value as String);
        }
      }
    }
    return ids;
  }

  Future<void> _applySnapshot(Map<String, dynamic> snapshot) async {
    final db = _store.db;
    await db.transaction(() async {
      await db.delete(db.localUserVocabularies).go();
      await db.delete(db.localFlashcards).go();
      await db.delete(db.localLookups).go();
      for (final item in snapshot['user_vocabularies'] as List? ?? const []) {
        await _store.putUserVocabulary(item as Map<String, dynamic>);
      }
      for (final item in snapshot['flashcards'] as List? ?? const []) {
        await _store.putFlashcard(item as Map<String, dynamic>);
      }
      for (final item in snapshot['translation_lookups'] as List? ?? const []) {
        await _store.putLookup(item as Map<String, dynamic>);
      }
      await _store.write(
        SyncKeys.userCollections,
        snapshot['user_collections'] ?? const [],
      );
      if (snapshot['preferences'] != null) {
        await _store.write(SyncKeys.preferences, snapshot['preferences']);
      }
      if (snapshot['profile'] != null) {
        await _store.write(SyncKeys.profile, snapshot['profile']);
      }
      await _store.write(SyncKeys.seq, (snapshot['seq'] as num).toInt());
    });
  }

  Future<void> _applyChange(SyncChange change) async {
    final data = change.data;
    switch (change.entity) {
      case 'user_vocabulary':
        change.deleted || data == null
            ? await _store.deleteUserVocabulary(change.id)
            : await _store.putUserVocabulary(data);
      case 'flashcard':
        change.deleted || data == null
            ? await _store.deleteFlashcard(change.id)
            : await _store.putFlashcard(data);
      case 'translation_lookup':
        change.deleted || data == null
            ? await _store.deleteLookup(change.id)
            : await _store.putLookup(data);
      case 'user_collection':
        final current = [
          for (final item
              in (await _store.read(SyncKeys.userCollections) as List?) ??
                  const [])
            item as Map<String, dynamic>,
        ]..removeWhere((item) => item['collection_id'] == change.id);
        if (!change.deleted && data != null) current.add(data);
        await _store.write(SyncKeys.userCollections, current);
      case 'preferences':
        if (data != null) await _store.write(SyncKeys.preferences, data);
      case 'profile':
        if (data != null) await _store.write(SyncKeys.profile, data);
    }
  }

  // --- Manifest ---

  Future<void> _checkManifest() async {
    try {
      final fresh = await _api.getManifest();
      final saved = await _store.read(SyncKeys.manifest) as Map?;
      final changed = <String>{
        for (final key in fresh.keys)
          if (saved == null || jsonEncode(saved[key]) != jsonEncode(fresh[key]))
            key,
      };
      await _store.write(SyncKeys.manifest, fresh);
      if (_alive && changed.isNotEmpty && saved != null) {
        ref.read(manifestChangedProvider.notifier).state = changed;
      }
    } catch (e, st) {
      if (!isConnectionError(e)) appLogger.handle(e, st, 'Manifest failed');
    }
  }

  /// Forgets everything of the account (sign out, signed out elsewhere).
  Future<void> reset() async {
    _stop();
    await _store.clearAll();
    _setState((_) => const SyncStatus());
  }
}

final syncEngineProvider = NotifierProvider<SyncEngine, SyncStatus>(
  SyncEngine.new,
);
