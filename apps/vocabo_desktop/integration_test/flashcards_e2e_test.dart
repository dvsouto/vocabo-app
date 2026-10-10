// End-to-end flashcards flow against a running API.
//
// Run it with `integration_test/e2e/run_flashcards_e2e.sh`, which recreates an
// empty test user and builds the app with ad hoc signing.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:window_manager/window_manager.dart';

import 'package:vocabo_desktop/src/app.dart';
import 'package:vocabo_desktop/src/config/env.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/screens/dashboard/dashboard_screen.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_flashcards_tab.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_panel.dart';

const _email = String.fromEnvironment(
  'E2E_EMAIL',
  defaultValue: 'e2e-flashcards@vocabo.test',
);
const _password = String.fromEnvironment(
  'E2E_PASSWORD',
  defaultValue: 'e2epass01',
);

// Comma separated terms added through the real search + add flow. Unknown
// terms are translated by OpenAI and get server-side audio generated.
const _termsDefine = String.fromEnvironment(
  'E2E_TERMS',
  defaultValue: 'coffee,calendar,stitch',
);
final _terms = _termsDefine.split(',').map((term) => term.trim()).toList();

String get _first => _terms[0];
String get _second => _terms[1];
String get _third => _terms[2];

/// Vocabulary returned by the API for each term, keyed by term.
final _vocabularies = <String, Vocabulary>{};

Vocabulary _vocab(String term) => _vocabularies[term]!;

final _boundaryKey = GlobalKey();
late Directory _shotsDir;
var _shotIndex = 0;

late VocaboApiClient _api;
late Dio _rawHttp;

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _pumpUntilTrue(
  WidgetTester tester,
  bool Function() condition, {
  required String description,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  throw TestFailure('Timed out waiting for $description');
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _snap(WidgetTester tester, String name) async {
  await _pumpFor(tester, const Duration(milliseconds: 600));
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  _shotIndex += 1;
  final file = File(
    '${_shotsDir.path}/${_shotIndex.toString().padLeft(2, '0')}-$name.png',
  );
  await file.writeAsBytes(bytes!);
  // ignore: avoid_print
  print('SCREENSHOT ${file.path}');
}

/// Mounts a fresh widget tree, which is how a cold app start looks to the
/// providers: every cached value is gone and must be reloaded from the API.
Future<void> _launchApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: ProviderScope(
        key: UniqueKey(),
        overrides: [apiClientProvider.overrideWithValue(_api)],
        child: const VocaboDesktopApp(),
      ),
    ),
  );
  await _pumpUntil(tester, find.text('PERSONAL WORKSPACE'));
}

/// The evaluation buttons scale in from zero, so taps must wait for the
/// entrance animation to finish or they miss the target.
Future<void> _waitForEvaluationBar(WidgetTester tester) async {
  await _pumpUntil(tester, find.text('Clear'));
  await _pumpFor(tester, const Duration(milliseconds: 900));
}

Finder _navItem(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(VocaboNavItem));

Finder _navBadge(String label, String badge) =>
    find.descendant(of: _navItem(label), matching: find.text(badge));

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(_navItem(label));
  await tester.pump();
}

Future<Map<String, dynamic>> _getData(String path) async {
  final response = await _rawHttp.get<Map<String, dynamic>>(path);
  return response.data!['data'] as Map<String, dynamic>;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initLogger(verbose: false);
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(1280, 860));
    await windowManager.center();

    _shotsDir = Directory('${Directory.systemTemp.path}/vocabo_e2e');
    if (_shotsDir.existsSync()) _shotsDir.deleteSync(recursive: true);
    _shotsDir.createSync(recursive: true);

    final tokenStorage = InMemoryTokenStorage();
    _api = VocaboApiClient(baseUrl: Env.apiUrl, tokenStorage: tokenStorage);
    await _api.auth.login(email: _email, password: _password);
    final token = await tokenStorage.getToken();

    _rawHttp = Dio(
      BaseOptions(
        baseUrl: Env.apiUrl,
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    await _addWords(_terms);
  });

  testWidgets('flashcards review flow end to end', (tester) async {
    await _runMainFlow(tester);
  });

  testWidgets('menu bar quick session', (tester) async {
    await _runTrayFlow(tester);
  });
}

/// Same path as the Add Word modal: search (find-or-translate) and add with
/// the content hash, which also triggers server-side audio.
Future<void> _addWords(List<String> terms) async {
  for (final term in terms) {
    final vocabulary = await _api.vocabulary.search(
      sourceLang: 'English',
      targetLang: 'Portuguese',
      term: term,
    );
    _vocabularies[term] = vocabulary;

    await _api.userVocabulary.add(
      data: {
        'term': vocabulary.term,
        'language': vocabulary.language,
        'translation': vocabulary.translation,
        'meaning': vocabulary.meaning ?? '',
        'word_type': vocabulary.wordType.value,
        'pronunciation': vocabulary.pronunciation ?? '',
        'tts_pronunciation': vocabulary.ttsPronunciation ?? '',
        'usage_examples': vocabulary.usageExamples!.toJson(),
        'content_hash': vocabulary.contentHash,
      },
    );
    // Distinct created_at values keep the deck order deterministic.
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> _runMainFlow(WidgetTester tester) async {
  await _launchApp(tester);

  // Sidebar exposes the new entry with the number of due cards.
  await _pumpUntil(tester, _navBadge('Flashcards', '3'));
  await _snap(tester, 'library-with-flashcards-badge');

  // Home: ready state.
  await _openTab(tester, 'Flashcards');
  await _pumpUntil(tester, find.text('3 words are waiting to be recalled'));
  expect(find.text('Review now'), findsOneWidget);
  expect(find.text('3 in rotation'), findsOneWidget);
  expect(find.text('About 1 minute · 3 new'), findsOneWidget);
  expect(find.text('Review now'), findsOneWidget);
  await _snap(tester, 'flashcards-home-ready');

  // Session 1 starts virtual: nothing is persisted until the first answer.
  await tester.tap(find.text('Review now'));
  await _pumpUntil(tester, find.text('0/3'));
  expect(find.text(_first), findsOneWidget);
  expect(find.text('Continue'), findsOneWidget);
  var status = await _getData('/flashcards/status');
  expect(status['has_active_session'], isFalse);
  await _snap(tester, 'session-card-front');

  // Audio: the card's listen button downloads the server-generated audio
  // and plays it to the end through the real player.
  final player = ProviderScope.containerOf(
    tester.element(find.byType(DashboardScreen)),
  ).read(audioPlayerServiceProvider);
  final audioStatuses = <AudioPlayerStatus>[];
  void recordStatus() => audioStatuses.add(player.state.status);
  player.addListener(recordStatus);

  await tester.tap(find.byTooltip('Listen'));
  await _pumpUntilTrue(
    tester,
    () => audioStatuses.contains(AudioPlayerStatus.playing),
    description: 'audio to start playing',
  );
  expect(find.byIcon(Icons.stop), findsOneWidget);
  await _pumpUntilTrue(
    tester,
    () => player.state.status == AudioPlayerStatus.idle,
    description: 'audio to finish playing',
  );
  player.removeListener(recordStatus);
  expect(audioStatuses, isNot(contains(AudioPlayerStatus.failed)));
  expect(audioStatuses.last, AudioPlayerStatus.idle);
  expect(find.byIcon(Icons.volume_up), findsOneWidget);
  await _snap(tester, 'session-card-audio-played');

  // Card 1 with the mouse: flip, reveal meaning, answer "hard".
  await tester.tap(find.text('Continue'));
  await _waitForEvaluationBar(tester);
  expect(find.text(_vocab(_first).translation ?? '—'), findsOneWidget);
  expect(find.text('How clear was it?'), findsOneWidget);
  // On a new card, Blank brings it back today and the other two tomorrow.
  expect(find.text('today'), findsOneWidget);
  expect(find.text('tomorrow'), findsNWidgets(2));
  await _snap(tester, 'session-card-back');

  await tester.tap(find.byTooltip('Show meaning'));
  await _pumpUntil(tester, find.text(_vocab(_first).meaning!));
  expect(find.text('EXAMPLES'), findsOneWidget);
  await _snap(tester, 'session-card-back-expanded');

  await tester.tap(find.text('Blank'));
  await _pumpUntil(tester, find.text('1/3'));
  status = await _getData('/flashcards/status');
  expect(status['has_active_session'], isTrue);

  // Card 2 with the keyboard: Space flips, "2" answers "medium".
  expect(find.text(_second), findsOneWidget);
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await _waitForEvaluationBar(tester);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
  await _pumpUntil(tester, find.text('2/3'));

  // Card 3 is archived. It has no history, so no confirmation is needed,
  // and being the last pending card it closes the session.
  expect(find.text(_third), findsOneWidget);
  await tester.tap(find.byTooltip('Set aside'));
  await _pumpUntil(tester, find.text('Session complete'));
  expect(
    find.textContaining('You recalled 2 words. None felt clear yet'),
    findsOneWidget,
  );
  expect(find.text('COMING BACK LATER TODAY'), findsOneWidget);
  expect(find.text(_first), findsOneWidget);
  await _snap(tester, 'session-1-complete');

  // Back home: the "hard" card is due again today and the archive has one.
  await tester.tap(find.text('Back to flashcards'));
  await _pumpUntil(tester, find.text('Archived (1)'));
  expect(find.text('Review now'), findsOneWidget);
  await _pumpUntil(tester, _navBadge('Flashcards', '1'));
  await _snap(tester, 'home-after-session-1');

  // Archived dialog: restore puts the card back at D+0.
  await tester.tap(find.text('Archived (1)'));
  await _pumpUntil(tester, find.text('Restore'));
  expect(find.text(_third), findsOneWidget);
  await _snap(tester, 'archived-dialog');

  await tester.tap(find.text('Restore'));
  await _pumpUntil(tester, find.text('No archived cards.'));
  await tester.tap(find.byIcon(Icons.close));
  await _pumpUntil(tester, _navBadge('Flashcards', '2'));
  expect(find.text('Archived'), findsOneWidget);

  // Session 2: the previous "hard" card leads the deck.
  await tester.tap(find.text('Review now'));
  await _pumpUntil(tester, find.text('0/2'));
  expect(find.text(_first), findsOneWidget);
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await _waitForEvaluationBar(tester);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
  await _pumpUntil(tester, find.text('1/2'));

  // Cold restart mid-session: the persisted session is resumed.
  await _launchApp(tester);
  await _openTab(tester, 'Flashcards');
  await _pumpUntil(tester, find.text('Continue reviewing'));
  await _snap(tester, 'home-resume-after-restart');

  await tester.tap(find.text('Continue reviewing'));
  await _pumpUntil(tester, find.text('1/2'));
  expect(find.text(_third), findsOneWidget);
  await tester.tap(find.text('Continue'));
  await _waitForEvaluationBar(tester);
  await tester.tap(find.text('Clear'));
  await _pumpUntil(tester, find.text('Session complete'));
  expect(
    find.text('You recalled 2 words. All of them felt clear.'),
    findsOneWidget,
  );
  expect(find.text('COMING BACK LATER TODAY'), findsNothing);
  await _snap(tester, 'session-2-complete');

  // Everything is scheduled for later: countdown, no badge.
  await tester.tap(find.text('Back to flashcards'));
  await _pumpUntil(tester, find.text('Your memory is in good shape.'));
  expect(find.text('Your next words return in'), findsOneWidget);
  expect(find.text('Review now'), findsNothing);
  await _pumpUntil(tester, find.text('Archived'));
  expect(_navBadge('Flashcards', '1'), findsNothing);
  await _snap(tester, 'home-countdown');

  // Library: hide meanings and check the preference is stored server side.
  await _openTab(tester, 'Library');
  await _pumpUntil(tester, find.text(_vocab(_first).meaning!));
  await _snap(tester, 'library-meanings-visible');

  await tester.tap(find.byTooltip('Hide meanings'));
  await _pumpUntil(tester, find.byTooltip('Show meanings'));
  expect(find.text(_vocab(_first).meaning!), findsNothing);
  await _pumpFor(tester, const Duration(milliseconds: 500));
  var preferences = await _getData('/user/preferences');
  expect(preferences['show_translations'], isFalse);
  await _snap(tester, 'library-meanings-hidden');

  // The preference survives a cold start.
  await _launchApp(tester);
  await _pumpUntil(tester, find.byTooltip('Show meanings'));
  await _pumpUntil(tester, find.text(_first));
  expect(find.text(_vocab(_first).meaning!), findsNothing);
  await _snap(tester, 'library-hidden-after-restart');

  await tester.tap(find.byTooltip('Show meanings'));
  await _pumpUntil(tester, find.text(_vocab(_first).meaning!));
  await _pumpFor(tester, const Duration(milliseconds: 500));
  preferences = await _getData('/user/preferences');
  expect(preferences['show_translations'], isTrue);

  // Word detail shows the real review stage and last practice date.
  await tester.tap(find.text(_first));
  await _pumpUntil(tester, find.text('FRESH'));
  expect(find.text('Not yet'), findsNothing);
  await _snap(tester, 'word-detail-review-stage');
}

const _trayTermsDefine = String.fromEnvironment(
  'E2E_TRAY_TERMS',
  defaultValue: 'police,potato,name,run',
);

/// Mounts the menu bar panel content, which normally runs in its own Flutter
/// engine, inside the test window with the same signed-in API client.
Future<void> _launchTrayPanel(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: ProviderScope(
        key: UniqueKey(),
        overrides: [apiClientProvider.overrideWithValue(_api)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: VocaboTheme.light(),
          home: Scaffold(
            backgroundColor: VocaboColors.surface,
            body: Center(
              child: SizedBox(
                width: 340,
                height: 500,
                child: Material(
                  color: VocaboColors.surfaceContainerLowest,
                  borderRadius: VocaboRadius.lg,
                  clipBehavior: Clip.antiAlias,
                  child: const TrayPanel(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await _pumpUntil(tester, find.text('Flashcards'));
}

Future<void> _runTrayFlow(WidgetTester tester) async {
  final trayTerms = _trayTermsDefine.split(',').map((t) => t.trim()).toList();
  await tester.runAsync(() => _addWords(trayTerms));

  await _launchTrayPanel(tester);
  await tester.tap(find.text('Flashcards'));
  await _pumpUntil(tester, find.text('4 words are waiting'));
  expect(find.text('A quick round of up to 3 words.'), findsOneWidget);
  await _snap(tester, 'tray-flashcards-home');

  await tester.tap(find.text('Quick session'));
  await _pumpUntil(tester, find.text('0/3'));
  expect(
    find.descendant(
      of: find.byType(TrayFlashcardsTab),
      matching: find.text(trayTerms[0]),
    ),
    findsOneWidget,
  );
  await _snap(tester, 'tray-session-front');

  // Keyboard first: the session takes focus away from the search field.
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await _waitForEvaluationBar(tester);
  await _snap(tester, 'tray-session-back');
  await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
  await _pumpUntil(tester, find.text('1/3'));

  for (final expected in ['2/3']) {
    await tester.tap(find.text('Continue'));
    await _waitForEvaluationBar(tester);
    await tester.tap(find.text('Clear'));
    await _pumpUntil(tester, find.text(expected));
  }

  await tester.tap(find.text('Continue'));
  await _waitForEvaluationBar(tester);
  await tester.tap(find.text('Fuzzy'));
  await _pumpUntil(tester, find.text('Round complete'));
  expect(find.text('You recalled 3 words. 2 felt clear.'), findsOneWidget);
  await _snap(tester, 'tray-round-complete');

  await tester.tap(find.text('Done'));
  await _pumpUntil(tester, find.text('1 word is waiting'));

  final status = await tester.runAsync(() => _getData('/flashcards/status'));
  expect(status!['due_count'], 1);
  expect(status['has_active_session'], isFalse);
}
