import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/models/flashcard_summary.dart';
import 'package:vocabo_core/src/models/vocabulary.dart';

/// A translation the user looked up, synced across devices.
class TranslationLookup extends Equatable {
  /// Lookups of a word outside the library before suggesting to save it.
  static const saveSuggestionThreshold = 3;

  final String id;
  final String vocabularyType;
  final int lookupCount;
  final DateTime lastLookedUpAt;
  final Vocabulary vocabulary;

  /// Library entry id when the word is already saved.
  final String? userVocabularyId;
  final FlashcardSummary? flashcard;

  const TranslationLookup({
    required this.id,
    required this.vocabularyType,
    required this.lookupCount,
    required this.lastLookedUpAt,
    required this.vocabulary,
    this.userVocabularyId,
    this.flashcard,
  });

  factory TranslationLookup.fromJson(Map<String, dynamic> json) {
    final flashcard = json['flashcard'];
    return TranslationLookup(
      id: json['id'] as String,
      vocabularyType: json['vocabulary_type'] as String? ?? 'system',
      lookupCount: json['lookup_count'] as int? ?? 1,
      lastLookedUpAt: DateTime.parse(json['last_looked_up_at'] as String),
      vocabulary: Vocabulary.fromJson(
        json['vocabulary'] as Map<String, dynamic>,
      ),
      userVocabularyId: json['user_vocabulary_id'] as String?,
      flashcard: flashcard is Map<String, dynamic>
          ? FlashcardSummary.fromJson(flashcard)
          : null,
    );
  }

  bool get isInLibrary => userVocabularyId != null;

  bool get shouldSuggestSaving =>
      !isInLibrary && lookupCount >= saveSuggestionThreshold;

  @override
  List<Object?> get props => [
    id,
    vocabularyType,
    lookupCount,
    lastLookedUpAt,
    vocabulary,
    userVocabularyId,
    flashcard,
  ];
}
