import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:vocabo_core/vocabo_core.dart' show appLogger;
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';

final _openLogViewerIntent = _OpenLogViewerIntent();

class _OpenLogViewerIntent extends Intent {
  const _OpenLogViewerIntent();
}

/// The app root shared by every platform: theme, locale, auth routing and
/// the global prompts. [shellBuilder] lets a host wrap the screens, e.g.
/// the desktop's menu bar shell.
class VocaboApp extends ConsumerWidget {
  const VocaboApp({super.key, this.shellBuilder});

  final Widget Function(Widget child)? shellBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStatus = ref.watch(authStatusProvider);

    ref.listen(userProfileProvider, (_, next) {
      final user = next.valueOrNull;
      if (user == null || !ref.read(confirmNativeLanguageProvider)) return;
      ref.read(confirmNativeLanguageProvider.notifier).state = false;
      final context = _navigatorKey.currentContext;
      if (context != null) showNativeLanguagePrompt(context, user);
    });

    ref.listen(upgradePromptProvider, (_, reason) {
      if (reason == null) return;
      ref.read(upgradePromptProvider.notifier).state = null;
      final context = _navigatorKey.currentContext;
      if (context != null) showPaywall(context, reason);
    });

    ref.listen(sessionNoticeProvider, (_, notice) {
      if (notice == null) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(notice), duration: const Duration(seconds: 6)),
      );
      ref.read(sessionNoticeProvider.notifier).state = null;
    });

    return MaterialApp(
      title: 'Vocabo',
      debugShowCheckedModeBanner: false,
      theme: VocaboTheme.light(),
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _messengerKey,
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
          child: _shell(
            authStatus.when(
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const LoginEmailScreen(),
              data: (status) => switch (status) {
                AuthStatus.authenticated => const DashboardScreen(),
                AuthStatus.needsVerification => const VerificationScreen(),
                AuthStatus.unauthenticated ||
                AuthStatus.unknown => const LoginEmailScreen(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _shell(Widget child) => shellBuilder?.call(child) ?? child;
}

final _navigatorKey = GlobalKey<NavigatorState>();
final _messengerKey = GlobalKey<ScaffoldMessengerState>();
