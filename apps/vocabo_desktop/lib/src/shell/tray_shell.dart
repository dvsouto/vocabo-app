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

    // Right-click menu only for quit
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
    // Left click: toggle tray panel
    ref.read(windowModeProvider.notifier).togglePanel();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'open':
        ref.read(windowModeProvider.notifier).showDashboard();
        break;
      case 'quit':
        windowManager.setPreventClose(false);
        exit(0);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
