import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dictionary_version.g.dart';

@JsonSerializable()
class DictionaryVersion extends Equatable {
  final String version;
  final String language;

  @JsonKey(name: 'word_count')
  final int wordCount;

  const DictionaryVersion({
    required this.version,
    required this.language,
    required this.wordCount,
  });

  factory DictionaryVersion.fromJson(Map<String, dynamic> json) =>
      _$DictionaryVersionFromJson(json);

  Map<String, dynamic> toJson() => _$DictionaryVersionToJson(this);

  @override
  List<Object?> get props => [version, language, wordCount];
}
