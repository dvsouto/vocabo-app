import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_database.g.dart';

/// Library words as the server returns them (`GET /user-vocabulary` items),
/// plus words added offline that the server has not confirmed yet.
class LocalUserVocabularies extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// True while only this device knows the word (outbox not flushed).
  BoolColumn get pending => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Flashcard state, with the columns the local deck composition filters on.
class LocalFlashcards extends Table {
  TextColumn get id => text()();
  TextColumn get userVocabularyId => text().nullable()();
  TextColumn get deck => text()();
  TextColumn get status => text()();
  DateTimeColumn get nextReviewAt => dateTime().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Spotlight and translation history.
class LocalLookups extends Table {
  TextColumn get id => text()();
  TextColumn get json => text()();
  DateTimeColumn get lookedUpAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single documents cached by key: profile, preferences, plan status, the
/// collections catalog, study note, recommendations, sync cursors.
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Writes waiting to reach the API, in order.
class OutboxOps extends Table {
  TextColumn get id => text()();
  IntColumn get position => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {id},
  ];
}

@DriftDatabase(
  tables: [
    LocalUserVocabularies,
    LocalFlashcards,
    LocalLookups,
    KeyValues,
    OutboxOps,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'vocabo_local'));

  @override
  int get schemaVersion => 1;

  /// Removes everything of the signed-in account.
  Future<void> clearAll() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });
}
