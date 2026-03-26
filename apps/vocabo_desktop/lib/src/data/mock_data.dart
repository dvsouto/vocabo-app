import 'package:vocabo_core/vocabo_core.dart';

abstract final class MockDashboardData {
  static const int streakDays = 12;
  static const int wordsThisWeek = 42;

  static final vocabularies = [
    Vocabulary(
      id: '1',
      term: 'Ephemeral',
      language: 'en',
      wordType: WordType.adjective,
      meaning: 'Lasting for a very short time.',
      pronunciation: '/ɪˈfem.ər.əl/',
      usageExamples: UsageExamples.fromJson({
        'English': ['"The ephemeral joys of summer."'],
      }),
    ),
    Vocabulary(
      id: '2',
      term: 'Sonder',
      language: 'en',
      wordType: WordType.noun,
      meaning:
          'The realization that each random passerby is living a life as vivid and complex as your own.',
      pronunciation: '/ˈsɒn.dər/',
      usageExamples: UsageExamples.fromJson({
        'English': [
          '"Walking through the terminal, he felt a deep sense of sonder."'
        ],
      }),
    ),
    Vocabulary(
      id: '3',
      term: 'Petrichor',
      language: 'en',
      wordType: WordType.noun,
      meaning:
          'A pleasant smell that frequently accompanies the first rain after a long period of warm, dry weather.',
      pronunciation: '/ˈpet.rɪ.kɔːr/',
      usageExamples: UsageExamples.fromJson({
        'English': ['"Other than the petrichor, the air was still."'],
      }),
    ),
  ];

  static const tags = <String, List<({String label, String variant})>>{
    '1': [
      (label: 'Mastered', variant: 'mastered'),
      (label: 'Academic', variant: 'outlined'),
    ],
    '2': [
      (label: 'Learning', variant: 'learning'),
      (label: 'Philosophical', variant: 'outlined'),
    ],
    '3': [
      (label: 'Mastered', variant: 'mastered'),
      (label: 'Nature', variant: 'outlined'),
    ],
  };

  static const lastPracticed = <String, String>{
    '1': 'Today, 10:45 AM',
    '2': 'Yesterday',
    '3': 'Yesterday',
  };

  // Tray panel words
  static final trayWords = [
    const Vocabulary(
      id: '4',
      term: 'Serendipity',
      language: 'en',
      wordType: WordType.noun,
      meaning:
          'Finding something valuable or delightful when not looking for it.',
      pronunciation: '/ˌser.ənˈdɪp.ɪ.ti/',
    ),
    const Vocabulary(
      id: '5',
      term: 'Luminous',
      language: 'en',
      wordType: WordType.adjective,
      meaning:
          'Shedding bright or radiant light, especially in the dark.',
      pronunciation: '/ˈluː.mɪ.nəs/',
    ),
    ...vocabularies.take(1),
  ];
}
