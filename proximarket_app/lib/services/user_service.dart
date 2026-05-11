import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import 'cloudinary_service.dart';

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
      throw 'Erreur lors de la récupération du profil : $e';
    }
  }

  // ─────────────────────────────────────────
  // CHOISIR UNE PHOTO
  // ─────────────────────────────────────────
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );
      // Retourne null si l'utilisateur annule — c'est normal, pas une erreur
      if (picked != null) return File(picked.path);
      return null;
    } catch (e) {
      throw 'Erreur lors de la sélection de la photo : $e';
    }
  }

  // ─────────────────────────────────────────
  // CHANGER LA PHOTO DE PROFIL
  // Retourne l'URL si succès, null si l'utilisateur a annulé la sélection
  // Lève une exception si l'upload échoue
  // ─────────────────────────────────────────
  Future<String?> changeProfilePhoto(String uid, ImageSource source) async {
    // 1. Sélectionner le fichier
    final file = await pickImage(source);

    // L'utilisateur a annulé la sélection → pas une erreur
    if (file == null) return null;

    // 2. Uploader sur Cloudinary
    final cloudinary = CloudinaryService();
    final url = await cloudinary.uploadProfilePhoto(file);

    // ✅ CORRECTION : si Cloudinary retourne null, lever une exception explicite
    // au lieu de ne rien faire et laisser Firestore non mis à jour
    if (url == null) {
      throw 'L\'upload de la photo a échoué. Vérifiez votre connexion et réessayez.';
    }

    // 3. Mettre à jour Firestore avec la nouvelle URL
    try {
      await _firestore.collection('users').doc(uid).update({
        'photoUrl': url,
      });
    } catch (e) {
      throw 'Photo uploadée mais erreur lors de la mise à jour du profil : $e';
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
      throw 'Erreur lors de la mise à jour du profil : $e';
    }
  }
}