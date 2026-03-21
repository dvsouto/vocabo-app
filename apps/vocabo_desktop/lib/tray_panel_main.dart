import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_panel.dart';

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
