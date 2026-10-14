import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:window_manager/window_manager.dart';

const _imageTypes = XTypeGroup(
  label: 'Images',
  extensions: ['png', 'jpg', 'jpeg', 'heic', 'webp'],
  uniformTypeIdentifiers: ['public.image'],
);

/// Desktop host: a window that may be hidden behind the menu bar icon, and
/// native open/save dialogs.
class DesktopPlatformAdapter extends PlatformAdapter {
  const DesktopPlatformAdapter();

  @override
  Future<void> bringToFront() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  bool get canPickImage => true;

  @override
  Future<Uint8List?> pickImage() async {
    final file = await openFile(acceptedTypeGroups: const [_imageTypes]);
    return file?.readAsBytes();
  }

  @override
  bool get canSaveFile => true;

  @override
  Future<bool> saveTextFile({
    required String suggestedName,
    required String content,
  }) async {
    final extension = suggestedName.split('.').last;
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(label: extension.toUpperCase(), extensions: [extension]),
      ],
    );
    if (location == null) return false;
    await File(location.path).writeAsString(content);
    return true;
  }
}
