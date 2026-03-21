import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:vocabo_core/src/enums/word_type.dart';
import 'package:vocabo_core/src/models/usage_examples.dart';

part 'vocabulary.g.dart';

@JsonSerializable()
class Vocabulary extends Equatable {
  @JsonKey(name: '_id')
  final String id;

  final String term;
  final String language;
  final String? translation;
  final String? meaning;

  @JsonKey(name: 'word_type')
  final WordType wordType;

  final String? pronunciation;

  @JsonKey(name: 'tts_pronunciation')
  final String? ttsPronunciation;

  @JsonKey(name: 'usage_examples')
  final UsageExamples? usageExamples;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const Vocabulary({
    required this.id,
    required this.term,
    required this.language,
    required this.wordType,
    this.translation,
    this.meaning,
    this.pronunciation,
    this.ttsPronunciation,
    this.usageExamples,
    this.createdAt,
    this.updatedAt,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) =>
      _$VocabularyFromJson(json);

  Map<String, dynamic> toJson() => _$VocabularyToJson(this);

  @override
  List<Object?> get props => [
        id,
        term,
        language,
        translation,
        meaning,
        wordType,
        pronunciation,
        ttsPronunciation,
        usageExamples,
        createdAt,
        updatedAt,
      ];
}
