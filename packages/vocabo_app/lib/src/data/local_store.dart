import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:vocabo_api/vocabo_api.dart';

import 'package:vocabo_app/src/data/local_database.dart';

const _uuid = Uuid();

/// A new id created on this device, accepted by the API for offline writes.
String newLocalId() => _uuid.v4();

LocalDatabase? _database;

/// One database per process: every provider scope (and the tests that
/// rebuild the app) shares it, so a disposed scope never closes it under a
/// write still in flight.
final localDatabaseProvider = Provider<LocalDatabase>(
  (ref) => _database ??= LocalDatabase(),
);

final localStoreProvider = Provider<LocalStore>(
  (ref) => LocalStore(ref.watch(localDatabaseProvider)),
);

/// Typed access to the local database, shared by the providers and the
/// sync engine. Rows keep the API's JSON so models decode them unchanged.
class LocalStore implements ResponseCache {
  LocalStore(this.db);

  final LocalDatabase db;

  // --- Key/value documents ---

  @override
  Future<Object?> read(String key) async {
    final row = await (db.select(
      db.keyValues,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.json);
  }

  Stream<Object?> watch(String key) =>
      (db.select(db.keyValues)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : jsonDecode(row.json));

  @override
  Future<void> write(String key, Object? value) => db
      .into(db.keyValues)
      .insertOnConflictUpdate(
        KeyValuesCompanion.insert(
          key: key,
          json: jsonEncode(value),
          updatedAt: DateTime.now(),
        ),
      );

  Future<void> remove(String key) =>
      (db.delete(db.keyValues)..where((t) => t.key.equals(key))).go();

  // --- Library ---

  Stream<List<Map<String, dynamic>>> watchUserVocabularies() =>
      (db.select(db.localUserVocabularies)..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
          .watch()
          .map(
            (rows) => [
              for (final row in rows)
                jsonDecode(row.json) as Map<String, dynamic>,
            ],
          );

  Future<Map<String, dynamic>?> readUserVocabulary(String id) async {
    final row = await (db.select(
      db.localUserVocabularies,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.json) as Map<String, dynamic>;
  }

  Future<void> putUserVocabulary(
    Map<String, dynamic> json, {
    bool pending = false,
  }) => db
      .into(db.localUserVocabularies)
      .insertOnConflictUpdate(
        LocalUserVocabulariesCompanion.insert(
          id: json['id'] as String,
          json: jsonEncode(json),
          createdAt: DateTime.parse(json['created_at'] as String),
          pending: Value(pending),
        ),
      );

  Future<void> deleteUserVocabulary(String id) => db.transaction(() async {
    await (db.delete(
      db.localUserVocabularies,
    )..where((t) => t.id.equals(id))).go();
    await (db.delete(
      db.localFlashcards,
    )..where((t) => t.userVocabularyId.equals(id))).go();
  });

  // --- Flashcards ---

  Stream<List<Map<String, dynamic>>> watchFlashcards() => db
      .select(db.localFlashcards)
      .watch()
      .map(
        (rows) => [
          for (final row in rows) jsonDecode(row.json) as Map<String, dynamic>,
        ],
      );

  Future<List<Map<String, dynamic>>> readFlashcards() async => [
    for (final row in await db.select(db.localFlashcards).get())
      jsonDecode(row.json) as Map<String, dynamic>,
  ];

  Future<Map<String, dynamic>?> readFlashcard(String id) async {
    final row = await (db.select(
      db.localFlashcards,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.json) as Map<String, dynamic>;
  }

  /// Saves the card and refreshes the review summary of its library word,
  /// which the API only sends with the word itself.
  Future<void> putFlashcard(Map<String, dynamic> json) => db.transaction(
    () async {
      await _insertFlashcard(json);
      final wordId = json['user_vocabulary_id'] as String?;
      if (wordId == null) return;
      final word = await readUserVocabulary(wordId);
      if (word == null) return;
      word['flashcard'] = {
        'id': json['id'],
        'status': json['status'],
        'current_stage_index': json['current_stage_index'],
        'next_review_at': json['next_review_at'],
      };
      await (db.update(db.localUserVocabularies)
            ..where((t) => t.id.equals(wordId)))
          .write(LocalUserVocabulariesCompanion(json: Value(jsonEncode(word))));
    },
  );

  Future<void> _insertFlashcard(Map<String, dynamic> json) => db
      .into(db.localFlashcards)
      .insertOnConflictUpdate(
        LocalFlashcardsCompanion.insert(
          id: json['id'] as String,
          userVocabularyId: Value(json['user_vocabulary_id'] as String?),
          deck: json['deck'] as String? ?? 'library',
          status: json['status'] as String? ?? 'active',
          nextReviewAt: Value(
            DateTime.tryParse(json['next_review_at'] as String? ?? ''),
          ),
          version: Value((json['version'] as num?)?.toInt() ?? 1),
          json: jsonEncode(json),
        ),
      );

  Future<void> deleteFlashcard(String id) =>
      (db.delete(db.localFlashcards)..where((t) => t.id.equals(id))).go();

  // --- Lookups ---

  Stream<List<Map<String, dynamic>>> watchLookups() =>
      (db.select(
        db.localLookups,
      )..orderBy([(t) => OrderingTerm.desc(t.lookedUpAt)])).watch().map(
        (rows) => [
          for (final row in rows) jsonDecode(row.json) as Map<String, dynamic>,
        ],
      );

  Future<void> putLookup(Map<String, dynamic> json) => db
      .into(db.localLookups)
      .insertOnConflictUpdate(
        LocalLookupsCompanion.insert(
          id: json['id'] as String,
          json: jsonEncode(json),
          lookedUpAt:
              DateTime.tryParse(
                json['last_looked_up_at'] as String? ??
                    json['updated_at'] as String? ??
                    '',
              ) ??
              DateTime.now(),
        ),
      );

  Future<void> deleteLookup(String id) =>
      (db.delete(db.localLookups)..where((t) => t.id.equals(id))).go();

  // --- Outbox ---

  /// Queues a write for the API. Returns the op id.
  Future<String> enqueue(String type, Map<String, dynamic> payload) async {
    final id = newLocalId();
    await db
        .into(db.outboxOps)
        .insert(
          OutboxOpsCompanion.insert(
            id: id,
            type: type,
            payload: jsonEncode(payload),
            createdAt: DateTime.now().toUtc(),
          ),
        );
    return id;
  }

  Future<List<OutboxOp>> pendingOps({int limit = 50}) =>
      (db.select(db.outboxOps)
            ..orderBy([(t) => OrderingTerm.asc(t.position)])
            ..limit(limit))
          .get();

  Stream<int> watchPendingCount() {
    final count = db.outboxOps.id.count();
    return (db.selectOnly(
      db.outboxOps,
    )..addColumns([count])).watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<void> removeOp(String id) =>
      (db.delete(db.outboxOps)..where((t) => t.id.equals(id))).go();

  Future<void> markOpFailed(String id, String error) async {
    final op = await (db.select(
      db.outboxOps,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (op == null) return;
    await (db.update(db.outboxOps)..where((t) => t.id.equals(id))).write(
      OutboxOpsCompanion(
        attempts: Value(op.attempts + 1),
        lastError: Value(error),
      ),
    );
  }

  /// Swaps a local id for the one the server already had (the same word
  /// added on another device), in the library and in queued ops.
  Future<void> rekeyUserVocabulary(String localId, String serverId) =>
      db.transaction(() async {
        await (db.delete(
          db.localUserVocabularies,
        )..where((t) => t.id.equals(localId))).go();
        await (db.delete(
          db.localFlashcards,
        )..where((t) => t.userVocabularyId.equals(localId))).go();
        for (final op in await db.select(db.outboxOps).get()) {
          if (!op.payload.contains(localId)) continue;
          await (db.update(
            db.outboxOps,
          )..where((t) => t.id.equals(op.id))).write(
            OutboxOpsCompanion(
              payload: Value(op.payload.replaceAll(localId, serverId)),
            ),
          );
        }
      });

  Future<void> clearAll() => db.clearAll();
}
