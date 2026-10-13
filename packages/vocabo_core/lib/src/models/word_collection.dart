import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/enums/collection_difficulty.dart';
import 'package:vocabo_core/src/models/vocabulary.dart';

/// A curated list of English words or phrases the user can study apart from
/// their library.
class WordCollection extends Equatable {
  final String id;
  final String slug;
  final String title;
  final String description;
  final CollectionDifficulty difficulty;
  final String category;
  final String icon;
  final int itemCount;
  final DateTime? addedAt;

  /// Words already reviewed at least once, once the collection was added.
  final int started;
  final int mastered;

  const WordCollection({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.icon,
    required this.itemCount,
    this.addedAt,
    this.started = 0,
    this.mastered = 0,
  });

  factory WordCollection.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>?;
    return WordCollection(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      difficulty: CollectionDifficulty.fromValue(json['difficulty'] as String?),
      category: json['category'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      itemCount: json['item_count'] as int? ?? 0,
      addedAt: DateTime.tryParse(json['added_at'] as String? ?? ''),
      started: progress?['started'] as int? ?? 0,
      mastered: progress?['mastered'] as int? ?? 0,
    );
  }

  bool get isAdded => addedAt != null;

  @override
  List<Object?> get props => [
    id,
    slug,
    title,
    description,
    difficulty,
    category,
    icon,
    itemCount,
    addedAt,
    started,
    mastered,
  ];
}

/// A word or phrase of a collection. [vocabulary] is null until it is
/// translated the first time someone opens it.
class CollectionItem extends Equatable {
  final String id;
  final String term;
  final Vocabulary? vocabulary;

  const CollectionItem({required this.id, required this.term, this.vocabulary});

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    final vocabulary = json['vocabulary'];
    return CollectionItem(
      id: json['id'] as String,
      term: json['term'] as String,
      vocabulary: vocabulary is Map<String, dynamic>
          ? Vocabulary.fromJson(vocabulary)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, term, vocabulary];
}

class CollectionDetail extends Equatable {
  final WordCollection collection;
  final List<CollectionItem> items;

  const CollectionDetail({required this.collection, required this.items});

  factory CollectionDetail.fromJson(Map<String, dynamic> json) {
    return CollectionDetail(
      collection: WordCollection.fromJson(
        json['collection'] as Map<String, dynamic>,
      ),
      items: [
        for (final item in (json['items'] as List<dynamic>? ?? const []))
          CollectionItem.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  @override
  List<Object?> get props => [collection, items];
}
