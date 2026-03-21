import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_examples.g.dart';

@JsonSerializable()
class UsageExamples extends Equatable {
  @JsonKey(name: 'source_lang', defaultValue: [])
  final List<String> sourceLang;

  @JsonKey(name: 'target_lang', defaultValue: [])
  final List<String> targetLang;

  const UsageExamples({
    this.sourceLang = const [],
    this.targetLang = const [],
  });

  factory UsageExamples.fromJson(Map<String, dynamic> json) =>
      _$UsageExamplesFromJson(json);

  Map<String, dynamic> toJson() => _$UsageExamplesToJson(this);

  @override
  List<Object?> get props => [sourceLang, targetLang];
}
