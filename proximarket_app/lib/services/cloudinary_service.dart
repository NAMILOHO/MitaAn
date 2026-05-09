import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String _cloudName = 'dsgykcs0n';
  static const String _uploadPreset = 'mitan_preset';

  // ─────────────────────────────────────────
  // UPLOADER UNE IMAGE (multipart - plus fiable)
  // ─────────────────────────────────────────
  Future<String?> uploadImage(File imageFile,
      {String folder = 'mitan'}) async {
    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      // Créer la requête multipart
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;

      // Ajouter le fichier
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Envoyer
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['secure_url'] as String;
        debugPrint('✅ Cloudinary OK : $imageUrl');
        return imageUrl;
      } else {
        debugPrint('❌ Cloudinary erreur ${response.statusCode}');
        debugPrint(response.body);
        return null;
      }
    } catch (e) {
      debugPrint('❌ Upload exception : $e');
      return null;
    }
  }

  // ─────────────────────────────────────────
  // UPLOADER PLUSIEURS IMAGES
  // ─────────────────────────────────────────
  Future<List<String>> uploadImages(
    List<File> images, {
    String folder = 'mitan/services',
  }) async {
    final List<String> urls = [];
    for (final image in images) {
      final url = await uploadImage(image, folder: folder);
      if (url != null) {
        urls.add(url);
        debugPrint('✅ Image ${urls.length} uploadée');
      }
    }
    debugPrint('✅ Total : ${urls.length}/${images.length} images uploadées');
    return urls;
  }

  // ─────────────────────────────────────────
  // UPLOADER PHOTO DE PROFIL
  // ─────────────────────────────────────────
  Future<String?> uploadProfilePhoto(File imageFile) async {
    return await uploadImage(imageFile, folder: 'mitan/profiles');
  }
}