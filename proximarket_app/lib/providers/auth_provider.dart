import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? errorMessage;
  User? user;

  AuthProvider() {
    _auth.authStateChanges().listen((User? u) {
      user = u;
      notifyListeners();
    });
  }

  // 🔥 SIGN UP
  Future<bool> signUp({
    required String email,
    required String password,
    required String nom,
    required String phone,
    required bool isPro,
    required String categorie,
  }) async {
    try {
      errorMessage = null;

      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // 🔥 SIGN IN
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      errorMessage = null;

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // 🔥 GOOGLE (placeholder si pas encore activé)
  Future<bool> signInWithGoogle() async {
    try {
      errorMessage = null;

      // TODO: ajouter google_sign_in plus tard
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
  }

  // 🔥 LOGOUT
  Future<void> signOut() async {
    await _auth.signOut();
  }
}