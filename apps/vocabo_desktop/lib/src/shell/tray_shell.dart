import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayShell extends ConsumerStatefulWidget {
  const TrayShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TrayShell> createState() => _TrayShellState();
}

class _TrayShellState extends ConsumerState<TrayShell>
    with TrayListener, WindowListener {
  static const _trayPanelChannel = MethodChannel('vocabo/tray_panel');

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
        windowManager.show();
        windowManager.focus();
        break;
      case 'quit':
        windowManager.setPreventClose(false);
        exit(0);
    }
  }

  Future<void> _toggleTrayPanel() async {
    try {
      final bounds = await trayManager.getBounds();
      if (bounds != null) {
        await _trayPanelChannel.invokeMethod('toggle', {
          'x': bounds.left,
          'y': bounds.top,
        });
      } else {
        await _trayPanelChannel.invokeMethod('toggle', {
          'x': 0.0,
          'y': 0.0,
        });
      }
    } catch (e) {
      debugPrint('TrayPanel toggle error: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
