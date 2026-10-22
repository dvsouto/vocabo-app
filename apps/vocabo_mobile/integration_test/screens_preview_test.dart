// Walks the main screens on a phone and saves screenshots under the app's
// Documents folder, so the layout can be reviewed on a simulator.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');
const _localeCode = String.fromEnvironment('AUDIT_LOCALE', defaultValue: 'en');
final _l = lookupAppLocalizations(Locale(_localeCode));

final _boundaryKey = GlobalKey();
late Directory _shotsDir;
var _shotIndex = 0;

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final deadline = DateTime.now().add(duration);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  await _snap(tester, 'timeout');
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _snap(WidgetTester tester, String name) async {
  await _pumpFor(tester, const Duration(milliseconds: 600));
  final exception = tester.takeException();
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  _shotIndex += 1;
  final file = File(
    '${_shotsDir.path}/${_shotIndex.toString().padLeft(2, '0')}-$name.png',
  );
  await file.writeAsBytes(bytes!);
  // The emulator app is removed after the run, so the image also goes to
  // the log, where the host can decode it.
  // ignore: avoid_print
  print('SHOT_B64 ${file.uri.pathSegments.last} ${base64Encode(bytes)}');
  // ignore: avoid_print
  print(
    'PREVIEW $name${exception == null ? '' : ' | EXCEPTION ${exception.toString().split('\n').first}'}',
  );
}

Future<void> _step(String name, Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    // ignore: avoid_print
    print('PREVIEW $name: STEP FAILED ${e.toString().split('\n').first}');
  }
}

Future<void> _launch(WidgetTester tester, VocaboApiClient api) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: const VocaboApp(),
      ),
    ),
  );
}

/// A section in the bottom bar (phones) or the sidebar (tablets).
Finder _navItem(String label) {
  final bottom = find.descendant(
    of: find.byType(DashboardBottomBar),
    matching: find.text(label),
  );
  if (bottom.evaluate().isNotEmpty) return bottom;
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(VocaboNavItem),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initLogger(verbose: false);
    await InterfaceLanguageStore().write(_localeCode);
    final documents = await getApplicationDocumentsDirectory();
    _shotsDir = Directory('${documents.path}/vocabo_preview');
    if (_shotsDir.existsSync()) _shotsDir.deleteSync(recursive: true);
    _shotsDir.createSync(recursive: true);
  });

  testWidgets('phone screens', (tester) async {
    final api = VocaboApiClient(
      baseUrl: Env.apiUrl,
      tokenStorage: InMemoryTokenStorage(),
    );
    await _launch(tester, api);
    await _pumpUntil(tester, find.text(_l.authContinueToLibrary));
    await _snap(tester, 'login');

    await tester.runAsync(
      () => api.auth.login(email: _email, password: _password),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await _launch(tester, api);
    await _pumpUntil(tester, find.text(_l.libraryTabMyWords));
    await _pumpFor(tester, const Duration(seconds: 2));
    await _snap(tester, 'library');

    await _step('word-detail', () async {
      final item = find.byType(VocabularyListItem);
      await tester.dragUntilVisible(
        item.first,
        find.byType(Scrollable).last,
        const Offset(0, -200),
      );
      await tester.pump();
      await tester.tap(item.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(seconds: 1));
      await _snap(tester, 'word-detail');
      await tester.binding.handlePopRoute();
      await _pumpFor(tester, const Duration(milliseconds: 500));
    });
    await _step('add-word', () async {
      await tester.tap(find.byType(FloatingActionButton));
      await _pumpFor(tester, const Duration(milliseconds: 800));
      await _snap(tester, 'add-word');
      await tester.binding.handlePopRoute();
      await _pumpFor(tester, const Duration(milliseconds: 500));
    });

    await _step('for-you', () async {
      await tester.tap(find.text(_l.libraryTabForYou));
      await _pumpFor(tester, const Duration(seconds: 4));
      await _snap(tester, 'for-you');
    });
    await _step('collections', () async {
      await tester.tap(find.text(_l.libraryTabCollections));
      await _pumpFor(tester, const Duration(seconds: 3));
      await _snap(tester, 'collections');
    });
    await _step('flashcards', () async {
      await tester.tap(_navItem(_l.sidebarFlashcards));
      await _pumpFor(tester, const Duration(seconds: 2));
      await _snap(tester, 'flashcards');
      final start = find.textContaining(
        RegExp(
          '^(${RegExp.escape(_l.flashcardsReviewNow)}|${RegExp.escape(_l.commonContinue)})',
        ),
      );
      if (start.evaluate().isNotEmpty) {
        await tester.tap(start.first);
        await _pumpFor(tester, const Duration(seconds: 2));
        await _snap(tester, 'flashcards-session');
        await tester.tap(find.text(_l.commonContinue).first);
        await _pumpFor(tester, const Duration(seconds: 2));
        await _snap(tester, 'flashcards-session-back');
      }
    });
    await _step('progress', () async {
      await tester.tap(_navItem(_l.sidebarProgress));
      await _pumpFor(tester, const Duration(seconds: 2));
      await _snap(tester, 'progress');
    });
    await _step('settings', () async {
      await tester.tap(_navItem(_l.sidebarSettings));
      await _pumpFor(tester, const Duration(seconds: 2));
      await _snap(tester, 'settings');
    });
    await _step('edit-profile', () async {
      await tester.tap(find.byTooltip(_l.settingsEditProfile));
      await _pumpFor(tester, const Duration(seconds: 1));
      await _snap(tester, 'edit-profile');
      await tester.binding.handlePopRoute();
      await _pumpFor(tester, const Duration(milliseconds: 600));
    });
  });
}
