import 'package:talker/talker.dart';

late Talker appLogger;

void initLogger({bool verbose = false}) {
  appLogger = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: true,
      maxHistoryItems: verbose ? 1000 : 200,
    ),
    logger: TalkerLogger(
      settings: TalkerLoggerSettings(
        level: verbose ? LogLevel.debug : LogLevel.info,
        enableColors: true,
      ),
    ),
  );
}
