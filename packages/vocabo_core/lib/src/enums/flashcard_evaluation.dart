import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum FlashcardEvaluation {
  hard('hard'),
  medium('medium'),
  easy('easy');

  const FlashcardEvaluation(this.value);
  final String value;

  static FlashcardEvaluation? fromValue(String? value) {
    if (value == null) return null;
    for (final evaluation in values) {
      if (evaluation.value == value) return evaluation;
    }
    return null;
  }
}
