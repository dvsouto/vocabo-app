import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vocabo_core/vocabo_core.dart' show appLogger;
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/screens/dashboard/dashboard_screen.dart';
import 'package:vocabo_desktop/src/screens/login/login_email_screen.dart';
import 'package:vocabo_desktop/src/shell/tray_shell.dart';

final _openLogViewerIntent = _OpenLogViewerIntent();

class _OpenLogViewerIntent extends Intent {
  const _OpenLogViewerIntent();
}

class VocaboDesktopApp extends ConsumerWidget {
  const VocaboDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);

    return MaterialApp(
      title: 'Vocabo',
      debugShowCheckedModeBanner: false,
      theme: VocaboTheme.light(),
      navigatorKey: _navigatorKey,
      home: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyL):
              _openLogViewerIntent,
        },
        child: Actions(
          actions: {
            _OpenLogViewerIntent: CallbackAction<_OpenLogViewerIntent>(
              onInvoke: (_) {
                _navigatorKey.currentState?.push(
                  MaterialPageRoute<void>(
                    builder: (_) => TalkerScreen(talker: appLogger),
                  ),
                );
                return null;
              },
            ),
          },
          child: TrayShell(
            child: authStatus.when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const LoginEmailScreen(),
              data: (status) => switch (status) {
                AuthStatus.authenticated => const DashboardScreen(),
                AuthStatus.unauthenticated || AuthStatus.unknown =>
                  const LoginEmailScreen(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

final _navigatorKey = GlobalKey<NavigatorState>();
