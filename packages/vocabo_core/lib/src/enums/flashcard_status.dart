import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum FlashcardStatus {
  active('active'),
  completed('completed'),
  archived('archived');

  const FlashcardStatus(this.value);
  final String value;

  static FlashcardStatus fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return FlashcardStatus.active;
  }
}

@JsonEnum(valueField: 'value')
enum FlashcardSessionStatus {
  inProgress('in_progress'),
  completed('completed');

  const FlashcardSessionStatus(this.value);
  final String value;

  static FlashcardSessionStatus fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return FlashcardSessionStatus.inProgress;
  }
}
