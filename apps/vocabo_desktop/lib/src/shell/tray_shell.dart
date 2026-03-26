import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vocabo_desktop/src/providers/add_word_providers.dart';

class TrayShell extends ConsumerStatefulWidget {
  const TrayShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TrayShell> createState() => _TrayShellState();
}

class _TrayShellState extends ConsumerState<TrayShell>
    with TrayListener, WindowListener {
  static const _trayPanelChannel = MethodChannel('vocabo/tray_panel');
  static const _trayActionsChannel =
      MethodChannel('vocabo/tray_panel_actions');
  DateTime _lastToggle = DateTime(2000);

  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTray();
    _initTrayActionsHandler();
  }

  void _initTrayActionsHandler() {
    _trayActionsChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'openAddWord':
          final term = call.arguments?['term'] as String? ?? '';
          ref.read(addWordInitialTermProvider.notifier).state = term;
          ref.read(showAddWordModalProvider.notifier).state = true;
          await windowManager.show();
          await windowManager.focus();
        case 'openApp':
          await windowManager.show();
          await windowManager.focus();
        case 'quitApp':
          await windowManager.setPreventClose(false);
          exit(0);
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
    await trayManager.setIcon('assets/tray_icon.png');
    await trayManager.setToolTip('Vocabo');

    final menu = Menu(items: [
      MenuItem(key: 'open', label: 'Open Vocabo'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]);
    await trayManager.setContextMenu(menu);
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    _toggleTrayPanel();
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
      debugPrint('TrayPanel toggle: bounds=$bounds, sending x=$x, y=$y');
      await _trayPanelChannel.invokeMethod('toggle', {
        'x': x,
        'y': y,
      });
    } catch (e) {
      debugPrint('TrayPanel toggle error: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
