import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

enum WindowMode { dashboard, panel }

final windowModeProvider =
    StateNotifierProvider<WindowModeNotifier, WindowMode>(
  (ref) => WindowModeNotifier(),
);

class WindowModeNotifier extends StateNotifier<WindowMode> {
  WindowModeNotifier() : super(WindowMode.dashboard);

  static const _panelSize = Size(340, 500);
  static const _dashboardMinSize = Size(900, 600);
  static const _dashboardSize = Size(1280, 800);

  Future<void> showPanel() async {
    if (state == WindowMode.panel && await windowManager.isVisible()) {
      await windowManager.focus();
      return;
    }

    state = WindowMode.panel;
    await windowManager.setMinimumSize(_panelSize);
    await windowManager.setSize(_panelSize);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setAlignment(Alignment.topRight);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> showDashboard() async {
    state = WindowMode.dashboard;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );
    await windowManager.setMinimumSize(_dashboardMinSize);
    await windowManager.setSize(_dashboardSize);
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> togglePanel() async {
    final isVisible = await windowManager.isVisible();

    if (isVisible && state == WindowMode.panel) {
      await windowManager.hide();
    } else {
      await showPanel();
    }
  }
}
