import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vocabo_api/vocabo_api.dart';

import 'package:vocabo_app/src/platform/platform_adapter.dart';

DeviceInfo describeDevice({
  String? appVersion,
  PlatformAdapter adapter = const PlatformAdapter(),
}) {
  final platform = adapter.platformName;
  return DeviceInfo(
    name: Platform.localHostname,
    platform: platform.length > 50 ? platform.substring(0, 50) : platform,
    appVersion: appVersion,
  );
}

/// Overridden in `main` with the app version once it is read.
final deviceInfoProvider = Provider<DeviceInfo>((_) => describeDevice());

Future<DeviceInfo> loadDeviceInfo() async {
  try {
    final info = await PackageInfo.fromPlatform();
    return describeDevice(appVersion: '${info.version}+${info.buildNumber}');
  } catch (e, st) {
    appLogger.handle(e, st, 'Could not read the app version');
    return describeDevice();
  }
}

/// Native language suggested from the system's preferred languages.
String systemNativeLanguage() {
  final locales = WidgetsBinding.instance.platformDispatcher.locales;
  return suggestNativeLanguage([
    for (final locale in locales)
      (languageCode: locale.languageCode, countryCode: locale.countryCode),
  ]);
}

/// Country of the system locale, used as the default phone country.
String systemCountryCode() {
  for (final locale in WidgetsBinding.instance.platformDispatcher.locales) {
    final country = locale.countryCode;
    if (country != null && phoneCountryByIso(country) != null) return country;
  }
  return 'US';
}
