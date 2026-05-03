import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Instances Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ─────────────────────────────────────────
  // INSCRIPTION
  // ─────────────────────────────────────────
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String nom,
    required String phone,
    required bool isPro,
    required String categorie,
  }) async {
    try {
      // 1. Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // 2. Créer le document Firestore
      final newUser = UserModel(
        uid: uid,
        nom: nom,
        email: email,
        phone: phone,
        isPro: isPro,
        categorie: categorie,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set({...newUser.toMap(), 'createdAt': FieldValue.serverTimestamp()});

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // ─────────────────────────────────────────
  // CONNEXION
  // ─────────────────────────────────────────
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;
      return await _getUserFromFirestore(uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e.code);
    }
  }

  // Ajoute ces imports en haut du fichier
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ─────────────────────────────────────────
// CONNEXION GOOGLE (Web + Mobile)
// ─────────────────────────────────────────
Future<UserModel?> signInWithGoogle() async {
  try {
    UserCredential userCredential;

    if (kIsWeb) {
      // ── Sur Web → utiliser GoogleAuthProvider avec popup ──
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // Ajouter le scope email
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Ouvre une popup Google
      userCredential = await _auth.signInWithPopup(googleProvider);

    } else {
      // ── Sur Mobile → utiliser google_sign_in normal ──
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // annulé par l'utilisateur

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _auth.signInWithCredential(credential);
    }

    final uid = userCredential.user!.uid;
    final googleUser = userCredential.user!;

    // Vérifier si l'utilisateur existe déjà dans Firestore
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      // Première connexion → créer le document Firestore
      final newUser = UserModel(
        uid: uid,
        nom: googleUser.displayName ?? '',
        email: googleUser.email ?? '',
        phone: '',
        photoUrl: googleUser.photoURL ?? '',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set({
        ...newUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return newUser;
    }

    // Utilisateur existant → retourner son profil
    return UserModel.fromMap(doc.data()!, uid);

  } on FirebaseAuthException catch (e) {
    // Erreur spécifique Firebase
    switch (e.code) {
      case 'popup-closed-by-user':
        throw 'Connexion annulée';
      case 'popup-blocked':
        throw 'Popup bloquée par le navigateur. '
            'Autorisez les popups pour localhost dans Chrome.';
      case 'cancelled-popup-request':
        throw 'Connexion annulée';
      default:
        throw _handleAuthError(e.code);
    }
  } catch (e) {
    throw 'Erreur lors de la connexion Google : $e';
  }
}
  // ─────────────────────────────────────────
  // DÉCONNEXION
  // ─────────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // déconnecte Google
    await _auth.signOut();         // déconnecte Firebase
  }

  // ─────────────────────────────────────────
  // RÉCUPÉRER UN UTILISATEUR DEPUIS FIRESTORE
  // ─────────────────────────────────────────
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  // ─────────────────────────────────────────
  // GESTION DES ERREURS EN FRANÇAIS
  // ─────────────────────────────────────────
  String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'user-not-found':
        return 'Aucun compte avec cet email';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'weak-password':
        return 'Le mot de passe est trop faible (minimum 6 caractères)';
      case 'network-request-failed':
        return 'Pas de connexion internet';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return 'Une erreur est survenue. Réessayez';
    }
  }
}
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  // ─────────────────────────────────────────
  // VÉRIFIER ET DEMANDER LES PERMISSIONS
  // ─────────────────────────────────────────
  Future<bool> _checkPermissions() async {
    // Vérifier si le GPS est activé sur le téléphone
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Le GPS est désactivé. Activez-le dans les paramètres.';
    }

    // Vérifier les permissions
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Demander la permission à l'utilisateur
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permission GPS refusée.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Permission GPS refusée définitivement. '
          'Activez-la dans les paramètres de l\'application.';
    }

    return true;
  }

  // ─────────────────────────────────────────
  // OBTENIR LA POSITION ACTUELLE
  // ─────────────────────────────────────────
  Future<Position> getCurrentPosition() async {
    await _checkPermissions();

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ─────────────────────────────────────────
  // CONVERTIR COORDONNÉES → NOM DE VILLE
  // ─────────────────────────────────────────
  Future<String> getCityFromCoordinates(
      double lat, double lng) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Retourne "Ville, Pays" ex: "Abidjan, Côte d'Ivoire"
        final city = place.locality ?? place.subAdministrativeArea ?? '';
        final country = place.country ?? '';
        return '$city, $country'.trim();
      }
      return 'Ville inconnue';
    } catch (e) {
      return 'Ville inconnue';
    }
  }

  // ─────────────────────────────────────────
  // SAUVEGARDER LA POSITION DANS FIRESTORE
  // ─────────────────────────────────────────
  Future<void> saveUserLocation(String uid) async {
    try {
      final position = await getCurrentPosition();
      final city = await getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'gpsLat': position.latitude,
        'gpsLng': position.longitude,
        'ville': city,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // ─────────────────────────────────────────
  // CALCULER LA DISTANCE ENTRE 2 POINTS (en km)
  // ─────────────────────────────────────────
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) /
        1000; // converti en km
  }
}