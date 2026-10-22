import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_core/vocabo_core.dart' show appLogger, initLogger;

import 'package:vocabo_mobile/src/mobile_platform_adapter.dart';
import 'package:vocabo_mobile/src/scheduled_daily_reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogger(verbose: kDebugMode);

  // Pronunciations must play even with the ring switch on silent.
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.speech());

  final device = await loadDeviceInfo();

  runApp(
    ProviderScope(
      observers: [TalkerRiverpodObserver(talker: appLogger)],
      overrides: [
        deviceInfoProvider.overrideWithValue(device),
        platformAdapterProvider.overrideWithValue(
          const MobilePlatformAdapter(),
        ),
        dailyReminderServiceProvider.overrideWith(
          (ref) => ref.watch(scheduledDailyReminderServiceProvider),
        ),
      ],
      child: const VocaboApp(),
    ),
  );
}
