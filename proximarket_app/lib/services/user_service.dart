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
      if (picked != null) return File(picked.path);
      return null;
    } catch (e) {
      throw 'Erreur lors de la sélection de la photo : $e';
    }
  }

  // ─────────────────────────────────────────
  // CHANGER LA PHOTO DE PROFIL
  // ─────────────────────────────────────────
  Future<String?> changeProfilePhoto(String uid, ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return null;

    final cloudinary = CloudinaryService();
    final url = await cloudinary.uploadProfilePhoto(file);

    if (url == null) {
      throw 'L\'upload de la photo a échoué. Vérifiez votre connexion et réessayez.';
    }

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

  // =============================================
  // NOUVELLES MÉTHODES : FAVORIS
  // =============================================

  Future<void> addFavorite(String uid, String serviceId) async {
    await _firestore.collection('users').doc(uid).update({
      'favorites': FieldValue.arrayUnion([serviceId]),
    });
  }

  Future<void> removeFavorite(String uid, String serviceId) async {
    await _firestore.collection('users').doc(uid).update({
      'favorites': FieldValue.arrayRemove([serviceId]),
    });
  }

  Future<List<String>> getFavorites(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return List<String>.from(doc.data()?['favorites'] ?? []);
  }
}