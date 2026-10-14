import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:vocabo_app/src/platform/platform_adapter.dart';

const _avatarMaxSide = 512;

/// Lets the user pick a photo and returns it as a PNG no larger than
/// 512 px per side, or null when cancelled.
Future<Uint8List?> pickAvatarPng(PlatformAdapter adapter) async {
  final bytes = await adapter.pickImage();
  if (bytes == null) return null;
  return resizeToPng(bytes);
}

Future<Uint8List> resizeToPng(
  Uint8List bytes, {
  int maxSide = _avatarMaxSide,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final codec = await ui.instantiateImageCodecWithSize(
    buffer,
    getTargetSize: (width, height) {
      final scale = maxSide / math.max(width, height);
      if (scale >= 1) return ui.TargetImageSize(width: width, height: height);
      return ui.TargetImageSize(
        width: (width * scale).round(),
        height: (height * scale).round(),
      );
    },
  );
  final frame = await codec.getNextFrame();
  final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  codec.dispose();
  return data!.buffer.asUint8List();
}
