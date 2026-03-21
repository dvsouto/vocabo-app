import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vocabo_desktop/src/providers/window_mode_provider.dart';

class TrayShell extends ConsumerStatefulWidget {
  const TrayShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TrayShell> createState() => _TrayShellState();
}

class _TrayShellState extends ConsumerState<TrayShell>
    with TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTray();
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
        _showMainWindow();
        break;
      case 'quit':
        windowManager.setPreventClose(false);
        exit(0);
    }
  }

  Future<void> _toggleTrayPanel() async {
    final isVisible = ref.read(trayPanelVisibleProvider);

    if (isVisible) {
      ref.read(trayPanelVisibleProvider.notifier).state = false;
    } else {
      // Ensure main window is visible first
      final windowVisible = await windowManager.isVisible();
      if (!windowVisible) {
        await windowManager.show();
        await windowManager.focus();
      }
      ref.read(trayPanelVisibleProvider.notifier).state = true;
    }
  }

  Future<void> _showMainWindow() async {
    ref.read(trayPanelVisibleProvider.notifier).state = false;
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
