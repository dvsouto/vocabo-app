import 'package:equatable/equatable.dart';

class StudyNoteTip extends Equatable {
  final String term;
  final String text;

  const StudyNoteTip({required this.term, required this.text});

  @override
  List<Object> get props => [term, text];
}

class StudyNoteChallenge extends Equatable {
  /// English sentence with the missing word shown as `____`.
  final String sentence;
  final String answer;

  const StudyNoteChallenge({required this.sentence, required this.answer});

  @override
  List<Object> get props => [sentence, answer];
}

/// The daily AI note on the user's study (Pro).
class StudyNote extends Equatable {
  final String day;

  /// True when nothing changed since this note was written.
  final bool unchanged;
  final String headline;
  final String summary;
  final List<StudyNoteTip> wordsAtRisk;
  final List<StudyNoteTip> watchOut;
  final String planToday;
  final StudyNoteChallenge? challenge;
  final String? milestone;

  const StudyNote({
    required this.day,
    required this.unchanged,
    required this.headline,
    required this.summary,
    this.wordsAtRisk = const [],
    this.watchOut = const [],
    required this.planToday,
    this.challenge,
    this.milestone,
  });

  factory StudyNote.fromJson(Map<String, dynamic> json) {
    List<StudyNoteTip> tips(String key, String textKey) => [
      for (final item in (json[key] as List<dynamic>? ?? const []))
        if (item is Map<String, dynamic>)
          StudyNoteTip(
            term: item['term'] as String? ?? '',
            text: item[textKey] as String? ?? '',
          ),
    ];
    final challenge = json['challenge'] as Map<String, dynamic>?;

    return StudyNote(
      day: json['day'] as String,
      unchanged: json['unchanged'] as bool? ?? false,
      headline: json['headline'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      wordsAtRisk: tips('words_at_risk', 'tip'),
      watchOut: tips('watch_out', 'note'),
      planToday: json['plan_today'] as String? ?? '',
      challenge: challenge == null
          ? null
          : StudyNoteChallenge(
              sentence: challenge['sentence'] as String? ?? '',
              answer: challenge['answer'] as String? ?? '',
            ),
      milestone: json['milestone'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    day,
    unchanged,
    headline,
    summary,
    wordsAtRisk,
    watchOut,
    planToday,
    challenge,
    milestone,
  ];
}
