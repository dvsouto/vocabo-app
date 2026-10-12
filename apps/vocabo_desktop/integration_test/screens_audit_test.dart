// Visual audit: walks every main-window screen at the minimum and default
// window sizes, saves screenshots and reports which areas scroll and how much.
//
// Run it with `integration_test/e2e/run_screens_audit.sh`.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:window_manager/window_manager.dart';

import 'package:vocabo_desktop/src/app.dart';
import 'package:vocabo_desktop/src/config/env.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';

const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');
const _unverifiedEmail = String.fromEnvironment('AUDIT_UNVERIFIED_EMAIL');

const _sizes = <String, Size>{
  'min': Size(800, 600),
  'default': Size(1280, 800),
};

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
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _snap(WidgetTester tester, String name) async {
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  _shotIndex += 1;
  final file = File(
    '${_shotsDir.path}/${_shotIndex.toString().padLeft(2, '0')}-$name.png',
  );
  await file.writeAsBytes(bytes!);
}

/// Describes every vertical scrollable that currently has content beyond its
/// viewport, ignoring the internal scrollables of text fields.
String _scrollReport(WidgetTester tester) {
  final reports = <String>[];
  for (final element in find.byType(Scrollable).evaluate()) {
    final state = (element as StatefulElement).state as ScrollableState;
    final position = state.position;
    if (!position.hasContentDimensions) continue;
    if (position.axis != Axis.vertical) continue;
    if (element.findAncestorWidgetOfExactType<EditableText>() != null) {
      continue;
    }
    if (position.maxScrollExtent <= 0.5) continue;
    final owner = element
        .findAncestorWidgetOfExactType<Dialog>()
        .runtimeType
        .toString();
    reports.add(
      'viewport=${position.viewportDimension.round()} '
      'overflow=${position.maxScrollExtent.round()}'
      '${owner == 'Null' ? '' : ' (dialog)'}',
    );
  }
  return reports.isEmpty ? 'no scroll' : reports.join('; ');
}

/// Screenshots the current screen at every audited window size and prints
/// the scroll report for each.
Future<void> _audit(WidgetTester tester, String name) async {
  for (final entry in _sizes.entries) {
    await tester.runAsync(() => windowManager.setSize(entry.value));
    await _pumpFor(tester, const Duration(milliseconds: 700));
    final exception = tester.takeException();
    await _snap(tester, '$name-${entry.key}');
    // ignore: avoid_print
    print(
      'AUDIT $name @${entry.key}: ${_scrollReport(tester)}'
      '${exception == null ? '' : ' | EXCEPTION ${exception.toString().split('\n').first}'}',
    );
  }
  await tester.runAsync(() => windowManager.setSize(_sizes['default']!));
  await _pumpFor(tester, const Duration(milliseconds: 400));
}

Future<void> _launch(WidgetTester tester, VocaboApiClient api) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: ProviderScope(
        key: UniqueKey(),
        overrides: [apiClientProvider.overrideWithValue(api)],
        child: const VocaboDesktopApp(),
      ),
    ),
  );
}

Future<void> _closeDialog(WidgetTester tester) async {
  final cancel = find.text('Cancel');
  if (cancel.evaluate().isNotEmpty) {
    await tester.tap(cancel.last);
  } else {
    await tester.tapAt(const Offset(10, 10));
  }
  await _pumpFor(tester, const Duration(milliseconds: 500));
}

Future<void> _step(String name, Future<void> Function() body) async {
  try {
    await body();
  } catch (e) {
    // ignore: avoid_print
    print('AUDIT $name: STEP FAILED ${e.toString().split('\n').first}');
  }
}

Finder _navItem(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(VocaboNavItem));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    initLogger(verbose: false);
    await windowManager.ensureInitialized();
    await windowManager.setSize(_sizes['default']!);
    await windowManager.center();
    _shotsDir = Directory('${Directory.systemTemp.path}/vocabo_audit');
    if (_shotsDir.existsSync()) _shotsDir.deleteSync(recursive: true);
    _shotsDir.createSync(recursive: true);
  });

  testWidgets('signed out screens', (tester) async {
    final api = VocaboApiClient(
      baseUrl: Env.apiUrl,
      tokenStorage: InMemoryTokenStorage(),
    );
    await _launch(tester, api);
    await _pumpUntil(tester, find.text('Continue to Library'));
    await _audit(tester, 'login-email');

    await _step('password-reset', () async {
      await tester.tap(find.text('FORGOT PASSWORD?'));
      await _pumpUntil(tester, find.text('Reset your password'));
      await _audit(tester, 'password-reset');
      await tester.tap(find.byTooltip('Back'));
      await _pumpFor(tester, const Duration(seconds: 1));
    });

    await _step('login-password', () async {
      await tester.enterText(find.byType(TextField).first, _email);
      await tester.tap(find.text('Continue to Library'));
      await _pumpUntil(tester, find.text('Enter Library'));
      await _audit(tester, 'login-password');
      await tester.tap(find.text('Back'));
      await _pumpFor(tester, const Duration(seconds: 1));
    });

    await _step('signup', () async {
      await tester.tap(find.text('CREATE ACCOUNT'));
      await _pumpUntil(tester, find.text('Create your account'));
      await _audit(tester, 'signup');
    });
  });

  testWidgets('verification screen', (tester) async {
    final storage = InMemoryTokenStorage();
    final api = VocaboApiClient(baseUrl: Env.apiUrl, tokenStorage: storage);
    await tester.runAsync(
      () => api.auth.login(email: _unverifiedEmail, password: _password),
    );
    await _launch(tester, api);
    await _pumpUntil(tester, find.text('Use another account'));
    await _audit(tester, 'verification');
  });

  testWidgets('signed in screens', (tester) async {
    final api = VocaboApiClient(
      baseUrl: Env.apiUrl,
      tokenStorage: InMemoryTokenStorage(),
    );
    await tester.runAsync(
      () => api.auth.login(email: _email, password: _password),
    );
    await _launch(tester, api);
    await _pumpUntil(tester, find.text('PERSONAL WORKSPACE'));
    await _pumpFor(tester, const Duration(seconds: 2));
    await _audit(tester, 'library');

    await _step('word-detail', () async {
      await tester.tap(find.text('run').first);
      await _pumpFor(tester, const Duration(seconds: 1));
      await _audit(tester, 'word-detail');
      await _closeDialog(tester);
    });

    await _step('add-word', () async {
      await tester.tap(find.text('Add New Word'));
      await _pumpFor(tester, const Duration(milliseconds: 800));
      await _audit(tester, 'add-word');
      await tester.enterText(find.byType(TextField).last, 'umbrella');
      await _pumpFor(tester, const Duration(seconds: 6));
      await _audit(tester, 'add-word-result');
      await _closeDialog(tester);
    });

    await _step('flashcards', () async {
      await tester.tap(_navItem('Flashcards'));
      await _pumpFor(tester, const Duration(seconds: 2));
      await _audit(tester, 'flashcards-home');
      final start = find.textContaining(RegExp(r'^(Review now|Continue)'));
      if (start.evaluate().isNotEmpty) {
        await tester.tap(start.first);
        await _pumpFor(tester, const Duration(seconds: 2));
        await _audit(tester, 'flashcards-session-front');
        await tester.tap(find.text('Continue').first);
        await _pumpFor(tester, const Duration(seconds: 2));
        await _audit(tester, 'flashcards-session-back');
      }
    });

    await _step('security', () async {
      await tester.tap(_navItem('Settings'));
      await _pumpFor(tester, const Duration(seconds: 2));
      await tester.ensureVisible(find.text('Privacy Policy'));
      await tester.tap(find.text('Privacy Policy'));
      await _pumpFor(tester, const Duration(seconds: 1));
      await _audit(tester, 'privacy');
      await tester.tap(find.byTooltip('Close'));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      await tester.ensureVisible(find.text('Change password'));
      await tester.tap(find.text('Change password'));
      await _pumpFor(tester, const Duration(seconds: 1));
      await _audit(tester, 'change-password');
      await _closeDialog(tester);
      await tester.ensureVisible(find.text('Delete account'));
      await tester.tap(find.text('Delete account'));
      await _pumpFor(tester, const Duration(seconds: 1));
      await _audit(tester, 'delete-account');
      await _closeDialog(tester);
    });

    await _step('archived', () async {
      await tester.tap(_navItem('Library'));
      await _pumpFor(tester, const Duration(milliseconds: 500));
      await tester.tap(_navItem('Flashcards'));
      await _pumpFor(tester, const Duration(seconds: 2));
      final stop = find.byTooltip('Stop');
      if (stop.evaluate().isNotEmpty) {
        await tester.tap(stop.first);
        await _pumpFor(tester, const Duration(seconds: 1));
      }
      await tester.tap(find.textContaining('Archived').first);
      await _pumpFor(tester, const Duration(seconds: 1));
      await _audit(tester, 'archived');
      await _closeDialog(tester);
    });

    await _step('progress', () async {
      await tester.tap(_navItem('Progress'));
      await _pumpFor(tester, const Duration(seconds: 2));
      await _audit(tester, 'progress');
    });

    await _step('settings', () async {
      await tester.tap(_navItem('Settings'));
      await _pumpFor(tester, const Duration(seconds: 2));
      await _audit(tester, 'settings');
    });

    await _step('edit-profile', () async {
      await tester.tap(find.text('Edit profile'));
      await _pumpFor(tester, const Duration(seconds: 1));
      await _audit(tester, 'edit-profile');
      await tester.tap(find.text('Add').first);
      await _pumpFor(tester, const Duration(seconds: 1));
      await _audit(tester, 'change-phone');
      await _closeDialog(tester);
      await _closeDialog(tester);
    });
  });
}
