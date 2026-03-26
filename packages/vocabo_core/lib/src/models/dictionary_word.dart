import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'dictionary_word.g.dart';

@JsonSerializable()
class DictionaryWord extends Equatable {
  final String word;
  final int frequency;

  const DictionaryWord({
    required this.word,
    required this.frequency,
  });

  factory DictionaryWord.fromJson(Map<String, dynamic> json) =>
      _$DictionaryWordFromJson(json);

  Map<String, dynamic> toJson() => _$DictionaryWordToJson(this);

  @override
  List<Object?> get props => [word, frequency];
}
