import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vocabo_desktop/src/app.dart';

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
