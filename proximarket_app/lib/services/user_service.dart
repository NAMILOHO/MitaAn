import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import 'cloudinary_service.dart';   // ← Import Cloudinary ajouté

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────
  // RÉCUPÉRER LE PROFIL UTILISATEUR
  // ─────────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw 'Erreur lors de la récupération du profil';
    }
  }

  // ─────────────────────────────────────────
  // CHOISIR UNE PHOTO (Optimisé)
  // ─────────────────────────────────────────
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );
      if (picked != null) return File(picked.path);
      return null;
    } catch (e) {
      throw 'Erreur lors de la sélection de la photo';
    }
  }

  // ─────────────────────────────────────────
  // TOUT EN UN : choisir + uploader sur Cloudinary + mettre à jour Firestore
  // ─────────────────────────────────────────
  Future<String?> changeProfilePhoto(String uid, ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return null;

    final cloudinary = CloudinaryService();
    final url = await cloudinary.uploadProfilePhoto(file);

    if (url != null) {
      await _firestore.collection('users').doc(uid).update({
        'photoUrl': url,
      });
    }

    return url;
  }

  // ─────────────────────────────────────────
  // METTRE À JOUR LE PROFIL DANS FIRESTORE
  // ─────────────────────────────────────────
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw 'Erreur lors de la mise à jour du profil';
    }
  }
}