import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayShell extends StatefulWidget {
  const TrayShell({super.key, required this.child});

  final Widget child;

  @override
  State<TrayShell> createState() => _TrayShellState();
}

class _TrayShellState extends State<TrayShell>
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
      MenuItem(key: 'show', label: 'Show Vocabo'),
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
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
        windowManager.focus();
        break;
      case 'quit':
        windowManager.setPreventClose(false);
        exit(0);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
