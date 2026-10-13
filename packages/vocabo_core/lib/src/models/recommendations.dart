import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/models/vocabulary.dart';
import 'package:vocabo_core/src/models/word_collection.dart';

class RecommendedWord extends Equatable {
  final String term;
  final String reason;
  final bool inLibrary;

  /// Null until the word is translated the first time it is opened.
  final Vocabulary? vocabulary;

  const RecommendedWord({
    required this.term,
    required this.reason,
    this.inLibrary = false,
    this.vocabulary,
  });

  factory RecommendedWord.fromJson(Map<String, dynamic> json) {
    final vocabulary = json['vocabulary'];
    return RecommendedWord(
      term: json['term'] as String,
      reason: json['reason'] as String? ?? '',
      inLibrary: json['in_library'] as bool? ?? false,
      vocabulary: vocabulary is Map<String, dynamic>
          ? Vocabulary.fromJson(vocabulary)
          : null,
    );
  }

  @override
  List<Object?> get props => [term, reason, inLibrary, vocabulary];
}

class RecommendedCollection extends Equatable {
  final WordCollection collection;
  final String reason;

  const RecommendedCollection({required this.collection, required this.reason});

  @override
  List<Object?> get props => [collection, reason];
}

/// Today's personalized words and collections (Pro). They are only made
/// once the user saved or translated a few words: until then
/// [needsMoreData] is true and only the counts are set.
class Recommendations extends Equatable {
  final bool needsMoreData;
  final int required;
  final int libraryWords;
  final int translatedWords;
  final String? day;

  /// True when nothing changed since these were made.
  final bool unchanged;
  final DateTime? createdAt;
  final String summary;
  final List<RecommendedWord> words;
  final List<RecommendedCollection> collections;

  const Recommendations({
    this.needsMoreData = false,
    this.required = 0,
    this.libraryWords = 0,
    this.translatedWords = 0,
    this.day,
    this.unchanged = false,
    this.createdAt,
    this.summary = '',
    this.words = const [],
    this.collections = const [],
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'needs_more_data') {
      return Recommendations(
        needsMoreData: true,
        required: json['required'] as int? ?? 3,
        libraryWords: json['library_words'] as int? ?? 0,
        translatedWords: json['translated_words'] as int? ?? 0,
      );
    }
    return Recommendations(
      day: json['day'] as String?,
      unchanged: json['unchanged'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      summary: json['summary'] as String? ?? '',
      words: [
        for (final word in (json['words'] as List<dynamic>? ?? const []))
          RecommendedWord.fromJson(word as Map<String, dynamic>),
      ],
      collections: [
        for (final entry in (json['collections'] as List<dynamic>? ?? const []))
          if (entry is Map<String, dynamic>)
            RecommendedCollection(
              collection: WordCollection.fromJson(
                entry['collection'] as Map<String, dynamic>,
              ),
              reason: entry['reason'] as String? ?? '',
            ),
      ],
    );
  }

  @override
  List<Object?> get props => [
    needsMoreData,
    required,
    libraryWords,
    translatedWords,
    day,
    unchanged,
    createdAt,
    summary,
    words,
    collections,
  ];
}
