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

/// Which side of the word is asked: forward shows the term and asks for its
/// meaning, reverse shows the meaning and asks for the term.
enum FlashcardDirection {
  forward,
  reverse;

  static FlashcardDirection fromValue(String? value) => value == 'reverse'
      ? FlashcardDirection.reverse
      : FlashcardDirection.forward;
}
