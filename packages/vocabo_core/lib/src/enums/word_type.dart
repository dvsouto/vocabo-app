import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum WordType {
  adjective('adjective'),
  adverb('adverb'),
  verb('verb'),
  noun('noun');

  const WordType(this.value);
  final String value;
}
