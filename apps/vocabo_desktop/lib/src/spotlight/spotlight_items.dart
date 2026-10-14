import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';

enum SpotlightSection {
  recent,
  library,
  dictionary,
  translate;

  String label(AppLocalizations l10n) => switch (this) {
    SpotlightSection.recent => l10n.spotlightSectionRecent,
    SpotlightSection.library => l10n.spotlightSectionLibrary,
    SpotlightSection.dictionary => l10n.spotlightSectionDictionary,
    SpotlightSection.translate => l10n.spotlightSectionTranslate,
  };
}

/// One row of the spotlight list.
class SpotlightItem {
  const SpotlightItem({
    required this.section,
    required this.term,
    this.vocabulary,
    this.vocabularyType = 'system',
    this.lookup,
    this.userVocabulary,
  });

  final SpotlightSection section;
  final String term;

  /// Full word data; null for dictionary and translate rows until resolved.
  final Vocabulary? vocabulary;
  final String vocabularyType;
  final TranslationLookup? lookup;
  final UserVocabulary? userVocabulary;

  String? get translation => vocabulary?.translation;

  bool get isResolved => vocabulary != null;

  String? get userVocabularyId =>
      userVocabulary?.id ?? lookup?.userVocabularyId;

  bool get isInLibrary => userVocabularyId != null;

  FlashcardSummary? get flashcard =>
      userVocabulary?.flashcard ?? lookup?.flashcard;

  bool get shouldSuggestSaving =>
      !isInLibrary && (lookup?.shouldSuggestSaving ?? false);

  String get key => '${section.name}:${vocabulary?.id ?? term.toLowerCase()}';
}

/// Builds the spotlight rows. With an empty query it shows the most recent
/// lookups; otherwise it ranks history and library matches (by term or by
/// translation), then dictionary words, and ends with a row to translate the
/// raw query when nothing matches it exactly.
List<SpotlightItem> buildSpotlightItems({
  required String query,
  required List<TranslationLookup> lookups,
  required List<UserVocabulary> library,
  required List<String> dictionaryWords,
  int recentLimit = 8,
  int knownLimit = 6,
  int dictionaryLimit = 4,
}) {
  final trimmed = query.trim();
  final libraryByVocabularyId = {
    for (final entry in library)
      if (entry.vocabulary != null) entry.vocabularyMongoId: entry,
  };

  if (trimmed.isEmpty) {
    return [
      for (final lookup in lookups.take(recentLimit))
        SpotlightItem(
          section: SpotlightSection.recent,
          term: lookup.vocabulary.term,
          vocabulary: lookup.vocabulary,
          vocabularyType: lookup.vocabularyType,
          lookup: lookup,
          userVocabulary: libraryByVocabularyId[lookup.vocabulary.id],
        ),
    ];
  }

  final scored = <(double, SpotlightItem)>[];
  final seenVocabularyIds = <String>{};

  for (final lookup in lookups) {
    final score = translationMatchScore(
      query: trimmed,
      term: lookup.vocabulary.term,
      translation: lookup.vocabulary.translation,
    );
    if (score <= 0) continue;
    seenVocabularyIds.add(lookup.vocabulary.id);
    scored.add((
      // History ranks slightly above the library at equal relevance.
      score + 0.01,
      SpotlightItem(
        section: SpotlightSection.recent,
        term: lookup.vocabulary.term,
        vocabulary: lookup.vocabulary,
        vocabularyType: lookup.vocabularyType,
        lookup: lookup,
        userVocabulary: libraryByVocabularyId[lookup.vocabulary.id],
      ),
    ));
  }

  for (final entry in library) {
    final vocabulary = entry.vocabulary;
    if (vocabulary == null || seenVocabularyIds.contains(vocabulary.id)) {
      continue;
    }
    final score = translationMatchScore(
      query: trimmed,
      term: vocabulary.term,
      translation: vocabulary.translation,
    );
    if (score <= 0) continue;
    seenVocabularyIds.add(vocabulary.id);
    scored.add((
      score,
      SpotlightItem(
        section: SpotlightSection.library,
        term: vocabulary.term,
        vocabulary: vocabulary,
        vocabularyType: entry.vocabularyType.value,
        userVocabulary: entry,
      ),
    ));
  }

  scored.sort((a, b) => b.$1.compareTo(a.$1));
  final known = scored.take(knownLimit).map((pair) => pair.$2).toList();
  final knownTerms = {for (final item in known) normalizeForMatch(item.term)};

  final dictionary = <SpotlightItem>[];
  for (final word in dictionaryWords) {
    if (dictionary.length >= dictionaryLimit) break;
    final normalized = normalizeForMatch(word);
    if (knownTerms.contains(normalized)) continue;
    knownTerms.add(normalized);
    dictionary.add(
      SpotlightItem(section: SpotlightSection.dictionary, term: word),
    );
  }

  final hasExactMatch =
      knownTerms.contains(normalizeForMatch(trimmed)) ||
      known.any(
        (item) =>
            item.translation != null &&
            normalizeForMatch(item.translation!) == normalizeForMatch(trimmed),
      );

  // Known words keep their own section; matches are ordered by relevance
  // inside each section.
  final recent = known.where((i) => i.section == SpotlightSection.recent);
  final saved = known.where((i) => i.section == SpotlightSection.library);

  return [
    ...recent,
    ...saved,
    ...dictionary,
    if (!hasExactMatch)
      SpotlightItem(section: SpotlightSection.translate, term: trimmed),
  ];
}
