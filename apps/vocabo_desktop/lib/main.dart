import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/app.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);
  await windowManager.setTitle('Vocabo');
  await windowManager.setMinimumSize(const Size(800, 600));
  await windowManager.setSize(const Size(1280, 800));
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: true,
  );
  await windowManager.center();

  runApp(
    const ProviderScope(
      child: VocaboDesktopApp(),
    ),
  );
}

@pragma('vm:entry-point')
void trayPanelMain() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VocaboTheme.light(),
      home: const Scaffold(
        backgroundColor: Colors.transparent,
        body: TrayPanel(),
      ),
    ),
  );
}
