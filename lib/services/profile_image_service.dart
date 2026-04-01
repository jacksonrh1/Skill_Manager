import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileImageService {
  ProfileImageService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndSaveResizedImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 95,
    );

    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final Uint8List resizedBytes = _resizeToAvatar(bytes);

    final directory = await getApplicationSupportDirectory();
    final avatarDirectory = Directory('${directory.path}/profile_images');
    if (!await avatarDirectory.exists()) {
      await avatarDirectory.create(recursive: true);
    }

    final path =
        '${avatarDirectory.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputFile = File(path);
    await outputFile.writeAsBytes(resizedBytes, flush: true);
    return outputFile.path;
  }

  static Uint8List _resizeToAvatar(Uint8List sourceBytes) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      return sourceBytes;
    }

    final resized = img.copyResizeCropSquare(
      decoded,
      size: 512,
      interpolation: img.Interpolation.cubic,
    );

    return Uint8List.fromList(
      img.encodeJpg(
        resized,
        quality: 88,
      ),
    );
  }
}
