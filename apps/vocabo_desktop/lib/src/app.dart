import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/screens/dashboard/dashboard_screen.dart';
import 'package:vocabo_desktop/src/screens/login/login_email_screen.dart';
import 'package:vocabo_desktop/src/shell/tray_shell.dart';

class VocaboDesktopApp extends ConsumerWidget {
  const VocaboDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);

    return MaterialApp(
      title: 'Vocabo',
      debugShowCheckedModeBanner: false,
      theme: VocaboTheme.light(),
      home: TrayShell(
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
    );
  }
}
