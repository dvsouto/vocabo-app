import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:vocabo_core/vocabo_core.dart' show initLogger, appLogger;
import 'package:window_manager/window_manager.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_desktop/src/app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_desktop/src/settings/spotlight_settings_card.dart';
import 'package:vocabo_desktop/src/shell/desktop_platform_adapter.dart';
import 'package:vocabo_desktop/src/spotlight/spotlight_view.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogger(verbose: kDebugMode);

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

  final device = await loadDeviceInfo();

  runApp(
    ProviderScope(
      observers: [TalkerRiverpodObserver(talker: appLogger)],
      overrides: [
        deviceInfoProvider.overrideWithValue(device),
        platformAdapterProvider.overrideWithValue(
          const DesktopPlatformAdapter(),
        ),
        platformSettingsCardProvider.overrideWithValue(
          const SpotlightSettingsCard(),
        ),
      ],
      child: const VocaboDesktopApp(),
    ),
  );
}

@pragma('vm:entry-point')
void trayPanelMain() {
  WidgetsFlutterBinding.ensureInitialized();
  initLogger(verbose: kDebugMode);

  runApp(
    ProviderScope(
      overrides: [syncEnabledProvider.overrideWithValue(false)],
      child: _LocalizedApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: VocaboColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: const TrayPanel(),
          ),
        ),
      ),
    ),
  );
}

@pragma('vm:entry-point')
void spotlightMain() {
  WidgetsFlutterBinding.ensureInitialized();
  initLogger(verbose: kDebugMode);

  runApp(
    ProviderScope(
      overrides: [syncEnabledProvider.overrideWithValue(false)],
      child: _LocalizedApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: SpotlightView(),
        ),
      ),
    ),
  );
}

/// App shell of the secondary engines (menu bar panel and spotlight), in
/// the interface language.
class _LocalizedApp extends ConsumerWidget {
  const _LocalizedApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: VocaboTheme.light(),
      locale: ref.watch(appLocaleProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }
}
