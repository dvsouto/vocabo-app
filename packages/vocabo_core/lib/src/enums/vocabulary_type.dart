import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum VocabularyType {
  system('system'),
  custom('custom');

  const VocabularyType(this.value);
  final String value;
}
