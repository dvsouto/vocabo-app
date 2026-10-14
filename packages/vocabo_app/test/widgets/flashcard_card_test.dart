import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

FlashcardSessionCard _card({
  required int stageIndex,
  required String direction,
  String? translation = 'efêmero',
}) {
  return FlashcardSessionCard.fromJson({
    'id': 'card-1',
    'position': 0,
    'evaluation': null,
    'flashcard': {
      'id': 'fc-1',
      'user_vocabulary_id': 'uv-1',
      'status': 'active',
      'current_stage_index': stageIndex,
      'stage_label': 'D+7',
      'direction': direction,
      'next_review_at': '2026-10-10T05:00:00.000Z',
      'has_regressed': false,
      'created_at': '2026-10-01T05:00:00.000Z',
      'updated_at': '2026-10-01T05:00:00.000Z',
      'vocabulary_type': 'system',
      'vocabulary': {
        '_id': 'm-1',
        'term': 'ephemeral',
        'language': 'English',
        'translation': translation,
        'meaning': 'Algo que dura pouco tempo.',
        'word_type': 'adjective',
        'pronunciation': '/ɪˈfem.ər.əl/',
        'content_hash': 'hash',
        'usage_examples': {
          'English': ['Fame is ephemeral.'],
        },
      },
    },
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        audioPlayerStateProvider.overrideWithValue(const AudioPlayerState()),
      ],
      child: MaterialApp(
        theme: VocaboTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('forward cards ask for the meaning of the term', (tester) async {
    await _pump(
      tester,
      FlashcardCard(
        card: _card(stageIndex: 2, direction: 'forward'),
        isFlipped: false,
        isExpanded: false,
        onFlip: () {},
        onToggleMeaning: () {},
      ),
    );

    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('efêmero'), findsNothing);
    expect(
      find.byTooltip('Listen · click again to hear it slowly'),
      findsOneWidget,
    );
    expect(find.text('FAMILIAR'), findsOneWidget);
  });

  testWidgets('reverse cards hide the term and its audio on the front', (
    tester,
  ) async {
    await _pump(
      tester,
      FlashcardCard(
        card: _card(stageIndex: 4, direction: 'reverse'),
        isFlipped: false,
        isExpanded: false,
        onFlip: () {},
        onToggleMeaning: () {},
      ),
    );

    expect(find.text('WHICH ENGLISH WORD IS THIS?'), findsOneWidget);
    expect(find.text('efêmero'), findsOneWidget);
    expect(find.text('ephemeral'), findsNothing);
    expect(
      find.byTooltip('Listen · click again to hear it slowly'),
      findsNothing,
    );
    expect(find.text('ANCHORED'), findsOneWidget);
  });

  testWidgets('reverse cards reveal the term with its audio on the back', (
    tester,
  ) async {
    await _pump(
      tester,
      FlashcardCard(
        card: _card(stageIndex: 4, direction: 'reverse'),
        isFlipped: true,
        isExpanded: false,
        onFlip: () {},
        onToggleMeaning: () {},
      ),
    );

    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('efêmero'), findsOneWidget);
    expect(
      find.byTooltip('Listen · click again to hear it slowly'),
      findsOneWidget,
    );
  });

  testWidgets('reverse cards fall back to the meaning without a translation', (
    tester,
  ) async {
    await _pump(
      tester,
      FlashcardCard(
        card: _card(stageIndex: 4, direction: 'reverse', translation: null),
        isFlipped: false,
        isExpanded: false,
        onFlip: () {},
        onToggleMeaning: () {},
      ),
    );

    expect(find.text('Algo que dura pouco tempo.'), findsOneWidget);
  });

  testWidgets('evaluation buttons tell when the card comes back', (
    tester,
  ) async {
    await _pump(
      tester,
      FlashcardEvaluationBar(
        selected: null,
        enabled: true,
        onEvaluate: (_) {},
        stageIndex: 3,
        stages: FlashcardConfig.fallback.stages,
      ),
    );

    expect(find.text('Blank'), findsOneWidget);
    expect(find.text('Fuzzy'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
    expect(find.text('today'), findsOneWidget);
    expect(find.text('tomorrow'), findsOneWidget);
    expect(find.text('in 2 days'), findsOneWidget);
  });
}
