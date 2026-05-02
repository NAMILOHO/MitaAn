import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

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

  // ─────────────────────────────────────────
  // CONNEXION GOOGLE
  // ─────────────────────────────────────────
  Future<UserModel?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // annulé par l'utilisateur

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      // Vérifier si l'utilisateur existe déjà dans Firestore
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        // Première connexion Google → créer le document
        final newUser = UserModel(
          uid: uid,
          nom: googleUser.displayName ?? '',
          email: googleUser.email,
          phone: '',
          photoUrl: googleUser.photoUrl ?? '',
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(uid).set(
            {...newUser.toMap(), 'createdAt': FieldValue.serverTimestamp()});

        return newUser;
      }

      return UserModel.fromMap(doc.data()!, uid);
    } catch (e) {
      throw 'Erreur lors de la connexion Google';
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