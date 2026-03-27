// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocabulary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vocabulary _$VocabularyFromJson(Map<String, dynamic> json) => Vocabulary(
  id: json['_id'] as String,
  term: json['term'] as String,
  language: json['language'] as String,
  wordType: $enumDecode(_$WordTypeEnumMap, json['word_type']),
  translation: json['translation'] as String?,
  meaning: json['meaning'] as String?,
  pronunciation: json['pronunciation'] as String?,
  ttsPronunciation: json['tts_pronunciation'] as String?,
  usageExamples: Vocabulary._usageExamplesFromJson(json['usage_examples']),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  contentHash: json['content_hash'] as String?,
);

Map<String, dynamic> _$VocabularyToJson(Vocabulary instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'term': instance.term,
      'language': instance.language,
      'translation': instance.translation,
      'meaning': instance.meaning,
      'word_type': _$WordTypeEnumMap[instance.wordType]!,
      'pronunciation': instance.pronunciation,
      'tts_pronunciation': instance.ttsPronunciation,
      'usage_examples': instance.usageExamples,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'content_hash': instance.contentHash,
    };

const _$WordTypeEnumMap = {
  WordType.adjective: 'adjective',
  WordType.adverb: 'adverb',
  WordType.verb: 'verb',
  WordType.noun: 'noun',
};
