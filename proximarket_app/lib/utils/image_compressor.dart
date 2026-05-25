import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageCompressor {
  ImageCompressor._();

  static const int _maxSizeBytes = 5 * 1024 * 1024;

  static bool exceedsLimit(File file) {
    return file.lengthSync() > _maxSizeBytes;
  }

  static String? validate(File file) {
    if (exceedsLimit(file)) {
      final mb = (file.lengthSync() / 1024 / 1024).toStringAsFixed(1);
      return 'Image trop lourde ($mb MB). Maximum 5 MB.';
    }
    return null;
  }

  static List<String> validateAll(List<File> files) {
    final errors = <String>[];
    for (int i = 0; i < files.length; i++) {
      final err = validate(files[i]);
      if (err != null) errors.add('Photo ${i + 1} : $err');
    }
    return errors;
  }

  static Future<File?> pickCompressed({
    required ImageSource source,
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 70,
  }) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );
    if (xfile == null) return null;
    return File(xfile.path);
  }

  static Future<List<File>> pickMultipleCompressed({
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 70,
  }) async {
    final picker = ImagePicker();
    final xfiles = await picker.pickMultiImage(
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
      imageQuality: quality,
    );
    return xfiles.map((xfile) => File(xfile.path)).toList();
  }

  static Future<void> logFileSize(File file, String label) async {
    final bytes = await file.length();
    final kb = bytes / 1024;
    debugPrint('📦 $label : ${kb.toStringAsFixed(1)} KB');
  }
}
