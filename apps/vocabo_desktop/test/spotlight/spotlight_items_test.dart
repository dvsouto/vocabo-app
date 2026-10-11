import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/spotlight/spotlight_items.dart';

Vocabulary _vocabulary(String id, String term, String translation) =>
    Vocabulary(
      id: id,
      term: term,
      language: 'English',
      wordType: WordType.noun,
      translation: translation,
    );

TranslationLookup _lookup(
  Vocabulary vocabulary, {
  int count = 1,
  String? userVocabularyId,
}) => TranslationLookup(
  id: 'lookup-${vocabulary.id}',
  vocabularyType: 'system',
  lookupCount: count,
  lastLookedUpAt: DateTime(2026, 10, 10),
  vocabulary: vocabulary,
  userVocabularyId: userVocabularyId,
);

UserVocabulary _entry(Vocabulary vocabulary) => UserVocabulary(
  id: 'uv-${vocabulary.id}',
  userId: 'user',
  vocabularyType: VocabularyType.system,
  vocabularyMongoId: vocabulary.id,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  vocabulary: vocabulary,
);

void main() {
  final chair = _vocabulary('v1', 'chair', 'cadeira');
  final coffee = _vocabulary('v2', 'coffee', 'café');
  final calendar = _vocabulary('v3', 'calendar', 'calendário');

  test('empty query lists recent lookups only', () {
    final items = buildSpotlightItems(
      query: '',
      lookups: [_lookup(chair), _lookup(coffee)],
      library: [_entry(calendar)],
      dictionaryWords: const [],
    );

    expect(items.map((i) => i.term), ['chair', 'coffee']);
    expect(items.every((i) => i.section == SpotlightSection.recent), isTrue);
  });

  test('matches history and library by translation, deduplicated', () {
    final items = buildSpotlightItems(
      query: 'caf',
      lookups: [_lookup(coffee)],
      library: [_entry(coffee), _entry(calendar)],
      dictionaryWords: const [],
    );

    expect(items.first.term, 'coffee');
    expect(items.first.section, SpotlightSection.recent);
    expect(items.first.isInLibrary, isTrue);
    expect(items.where((i) => i.term == 'coffee'), hasLength(1));
    expect(items.last.section, SpotlightSection.translate);
  });

  test('adds dictionary words not already known and a translate row', () {
    final items = buildSpotlightItems(
      query: 'cha',
      lookups: [_lookup(chair)],
      library: const [],
      dictionaryWords: const ['chair', 'chance', 'change'],
    );

    expect(items.map((i) => (i.section, i.term)), [
      (SpotlightSection.recent, 'chair'),
      (SpotlightSection.dictionary, 'chance'),
      (SpotlightSection.dictionary, 'change'),
      (SpotlightSection.translate, 'cha'),
    ]);
  });

  test('hides the translate row on an exact term or translation match', () {
    List<SpotlightSection> sections(String query) => buildSpotlightItems(
      query: query,
      lookups: [_lookup(chair)],
      library: const [],
      dictionaryWords: const [],
    ).map((i) => i.section).toList();

    expect(sections('chair'), [SpotlightSection.recent]);
    expect(sections('Cadeira'), [SpotlightSection.recent]);
  });

  test('suggests saving after repeated lookups outside the library', () {
    final repeated = buildSpotlightItems(
      query: '',
      lookups: [_lookup(chair, count: 3)],
      library: const [],
      dictionaryWords: const [],
    ).single;
    final saved = buildSpotlightItems(
      query: '',
      lookups: [_lookup(chair, count: 5, userVocabularyId: 'uv-v1')],
      library: const [],
      dictionaryWords: const [],
    ).single;

    expect(repeated.shouldSuggestSaving, isTrue);
    expect(saved.shouldSuggestSaving, isFalse);
  });
}
