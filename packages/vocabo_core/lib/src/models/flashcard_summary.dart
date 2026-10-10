import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/enums/flashcard_status.dart';
import 'package:vocabo_core/src/utils/memory_strength.dart';

/// Review state attached to each library entry.
class FlashcardSummary extends Equatable {
  final String id;
  final FlashcardStatus status;
  final int currentStageIndex;
  final DateTime? nextReviewAt;

  const FlashcardSummary({
    required this.id,
    required this.status,
    required this.currentStageIndex,
    this.nextReviewAt,
  });

  factory FlashcardSummary.fromJson(Map<String, dynamic> json) {
    return FlashcardSummary(
      id: json['id'] as String,
      status: FlashcardStatus.fromValue(json['status'] as String?),
      currentStageIndex: json['current_stage_index'] as int? ?? 0,
      nextReviewAt: json['next_review_at'] == null
          ? null
          : DateTime.parse(json['next_review_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.value,
    'current_stage_index': currentStageIndex,
    'next_review_at': nextReviewAt?.toIso8601String(),
  };

  MemoryStrength get strength =>
      MemoryStrength.of(stageIndex: currentStageIndex, status: status);

  @override
  List<Object?> get props => [id, status, currentStageIndex, nextReviewAt];
}
