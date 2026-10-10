import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:vocabo_core/src/enums/vocabulary_type.dart';
import 'package:vocabo_core/src/models/flashcard_summary.dart';
import 'package:vocabo_core/src/models/vocabulary.dart';

part 'user_vocabulary.g.dart';

@JsonSerializable()
class UserVocabulary extends Equatable {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'vocabulary_type')
  final VocabularyType vocabularyType;

  @JsonKey(name: 'vocabulary_mongo_id')
  final String vocabularyMongoId;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  final Vocabulary? vocabulary;

  @JsonKey(fromJson: _flashcardFromJson, toJson: _flashcardToJson)
  final FlashcardSummary? flashcard;

  const UserVocabulary({
    required this.id,
    required this.userId,
    required this.vocabularyType,
    required this.vocabularyMongoId,
    required this.createdAt,
    required this.updatedAt,
    this.vocabulary,
    this.flashcard,
  });

  factory UserVocabulary.fromJson(Map<String, dynamic> json) =>
      _$UserVocabularyFromJson(json);

  Map<String, dynamic> toJson() => _$UserVocabularyToJson(this);

  static FlashcardSummary? _flashcardFromJson(dynamic json) =>
      json is Map<String, dynamic> ? FlashcardSummary.fromJson(json) : null;

  static Map<String, dynamic>? _flashcardToJson(FlashcardSummary? summary) =>
      summary?.toJson();

  @override
  List<Object?> get props => [
    id,
    userId,
    vocabularyType,
    vocabularyMongoId,
    createdAt,
    updatedAt,
    vocabulary,
    flashcard,
  ];
}
