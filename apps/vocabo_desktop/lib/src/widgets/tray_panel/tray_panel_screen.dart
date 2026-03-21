import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/window_mode_provider.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_panel.dart';

class TrayPanelScreen extends ConsumerWidget {
  const TrayPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      body: TrayPanel(
        onOpenDashboard: () {
          ref.read(windowModeProvider.notifier).showDashboard();
        },
      ),
    );
  }
}
