import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _userModel;
  bool _isLoading = false;
  String? errorMessage;

  // Getters
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  // ─────────────────────────────────────────
  // INSCRIPTION
  // ─────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String nom,
    required String phone,
    required bool isPro,
    required String categorie,
  }) async {
    _setLoading(true);
    try {
      errorMessage = null;
      _userModel = await _authService.signUp(
        email: email,
        password: password,
        nom: nom,
        phone: phone,
        isPro: isPro,
        categorie: categorie,
      );
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // CONNEXION EMAIL
  // ─────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      errorMessage = null;
      _userModel = await _authService.signIn(
        email: email,
        password: password,
      );
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // CONNEXION GOOGLE
  // ─────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      errorMessage = null;

      if (kIsWeb) {
        // Sur Web → popup Firebase
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
        _userModel = null; // sera chargé par le stream
        notifyListeners();
        return true;
      } else {
        // Sur Mobile → google_sign_in
        _userModel = await _authService.signInWithGoogle();
        notifyListeners();
        return _userModel != null;
      }
    } catch (e) {
      errorMessage = 'Erreur Google : ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // DÉCONNEXION
  // ─────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _userModel = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}