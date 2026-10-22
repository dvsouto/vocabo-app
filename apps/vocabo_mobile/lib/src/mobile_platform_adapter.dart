import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vocabo_app/vocabo_app.dart';

/// Phone host: photos come from the gallery and files go out through the
/// share sheet.
class MobilePlatformAdapter extends PlatformAdapter {
  const MobilePlatformAdapter();

  @override
  bool get canPickImage => true;

  @override
  Future<Uint8List?> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    return file?.readAsBytes();
  }

  @override
  bool get canSaveFile => true;

  @override
  Future<bool> saveTextFile({
    required String suggestedName,
    required String content,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$suggestedName');
    await file.writeAsString(content);
    final result = await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)]),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}
