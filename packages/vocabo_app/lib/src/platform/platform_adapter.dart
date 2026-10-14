import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

/// What the shared logic needs from the host app and operating system.
/// Each app overrides [platformAdapterProvider] with its own version.
class PlatformAdapter {
  const PlatformAdapter();

  /// Operating system and version as sent to the API with each session.
  String get platformName {
    final os = switch (Platform.operatingSystem) {
      'macos' => 'macOS',
      'ios' => 'iOS',
      'android' => 'Android',
      final other => other,
    };
    return '$os ${Platform.operatingSystemVersion}';
  }

  /// Brings the app to the foreground, e.g. after a notification tap.
  /// Nothing to do on mobile; the desktop shows and focuses its window.
  Future<void> bringToFront() async {}

  /// Whether [pickImage] can open a chooser on this platform.
  bool get canPickImage => false;

  /// Lets the user choose a photo; null when cancelled or unsupported.
  Future<Uint8List?> pickImage() async => null;

  /// Whether [saveTextFile] can hand a file to the user on this platform.
  bool get canSaveFile => false;

  /// Saves (desktop) or shares (mobile) a text file. Returns false when
  /// the user cancelled.
  Future<bool> saveTextFile({
    required String suggestedName,
    required String content,
  }) async => false;
}

final platformAdapterProvider = Provider<PlatformAdapter>(
  (_) => const PlatformAdapter(),
);

/// An extra card the host app adds to the settings screen, such as the
/// desktop's keyboard shortcut toggle. Null when it has none.
final platformSettingsCardProvider = Provider<Widget?>((_) => null);
