import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vocabo_core/vocabo_core.dart' show appLogger;
import 'package:window_manager/window_manager.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/l10n/locale_providers.dart';
import 'package:vocabo_desktop/src/providers/add_word_providers.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/providers/dashboard_providers.dart';
import 'package:vocabo_desktop/src/providers/spotlight_providers.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/providers/word_detail_providers.dart';

class TrayShell extends ConsumerStatefulWidget {
  const TrayShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TrayShell> createState() => _TrayShellState();
}

class _TrayShellState extends ConsumerState<TrayShell>
    with TrayListener, WindowListener {
  static const _trayPanelChannel = MethodChannel('vocabo/tray_panel');
  static const _spotlightChannel = MethodChannel('vocabo/spotlight');
  DateTime _lastToggle = DateTime(2000);

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTray();
    _initMainChannelHandler();
    _initSpotlightChannelHandler();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncSpotlight());
  }

  /// The hotkey is only active while signed in and enabled in Settings.
  void _syncSpotlight() {
    final isAuthenticated =
        ref.read(authStatusProvider).valueOrNull == AuthStatus.authenticated;
    final enabled = ref.read(spotlightEnabledProvider).valueOrNull ?? false;
    _spotlightChannel
        .invokeMethod('setEnabled', {'enabled': isAuthenticated && enabled})
        .catchError((Object e) {
          appLogger.error('Spotlight setEnabled error', e);
        });
  }

  void _initSpotlightChannelHandler() {
    _spotlightChannel.setMethodCallHandler((call) async {
      final args = call.arguments as Map?;
      switch (call.method) {
        case 'openWord':
          _openWord(
            userVocabularyId: args?['user_vocabulary_id'] as String?,
            term: args?['term'] as String? ?? '',
          );
        case 'vocabularyChanged':
          ref.read(userVocabularyListProvider.notifier).refresh();
      }
    });
  }

  void _openWord({String? userVocabularyId, required String term}) {
    windowManager.show();
    windowManager.focus();

    final entries = ref.read(userVocabularyListProvider).valueOrNull ?? [];
    final entry = userVocabularyId == null
        ? null
        : entries.where((e) => e.id == userVocabularyId).firstOrNull;

    if (entry != null) {
      ref.read(dashboardSectionProvider.notifier).state =
          DashboardSection.library;
      ref.read(selectedWordProvider.notifier).state = entry;
      ref.read(showWordDetailModalProvider.notifier).state = true;
      return;
    }

    if (userVocabularyId != null) {
      ref.read(dashboardSectionProvider.notifier).state =
          DashboardSection.library;
      return;
    }

    ref.read(addWordInitialTermProvider.notifier).state = term;
    ref.read(showAddWordModalProvider.notifier).state = true;
  }

  void _initMainChannelHandler() {
    _trayPanelChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'openAddWord':
          final args = call.arguments as Map?;
          final term = args?['term'] as String? ?? '';
          ref.read(addWordInitialTermProvider.notifier).state = term;
          ref.read(showAddWordModalProvider.notifier).state = true;
        case 'openFlashcards':
          ref.read(dashboardSectionProvider.notifier).state =
              DashboardSection.flashcards;
      }
    });
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initTray() async {
    await trayManager.setIcon('assets/tray_icon.png', isTemplate: true);
    await trayManager.setToolTip('Vocabo');
    await _buildTrayMenu(ref.read(appLocaleProvider));
  }

  Future<void> _buildTrayMenu(Locale locale) async {
    final l10n = lookupAppLocalizations(locale);
    final menu = Menu(
      items: [
        MenuItem(key: 'open', label: l10n.trayMenuOpen),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: l10n.trayMenuQuit),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    final authStatus = ref.read(authStatusProvider);
    final isAuthenticated = authStatus.valueOrNull == AuthStatus.authenticated;
    if (isAuthenticated) {
      _toggleTrayPanel();
    } else {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open':
        windowManager.show();
        windowManager.focus();
        break;
      case 'quit':
        windowManager.setPreventClose(false);
        exit(0);
    }
  }

  Future<void> _toggleTrayPanel() async {
    // Debounce: ignore toggles within 300ms to prevent double-fire
    final now = DateTime.now();
    if (now.difference(_lastToggle).inMilliseconds < 300) return;
    _lastToggle = now;

    try {
      final bounds = await trayManager.getBounds();
      final x = bounds?.left ?? 0.0;
      final y = bounds?.top ?? 0.0;
      appLogger.debug('TrayPanel toggle: bounds=$bounds, sending x=$x, y=$y');
      await _trayPanelChannel.invokeMethod('toggle', {'x': x, 'y': y});
    } catch (e) {
      appLogger.error('TrayPanel toggle error', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStatusProvider, (_, _) => _syncSpotlight());
    ref.listen(spotlightEnabledProvider, (_, _) => _syncSpotlight());
    ref.listen(appLocaleProvider, (_, locale) => _buildTrayMenu(locale));
    return widget.child;
  }
}
