import 'package:flutter/widgets.dart';
import 'package:vocabo_app/vocabo_app.dart';

import 'package:vocabo_desktop/src/shell/tray_shell.dart';

/// The shared app wrapped in the menu bar shell.
class VocaboDesktopApp extends StatelessWidget {
  const VocaboDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return VocaboApp(shellBuilder: (child) => TrayShell(child: child));
  }
}
