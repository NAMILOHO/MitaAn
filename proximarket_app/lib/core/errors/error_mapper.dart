import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

/// Convertit les exceptions brutes (Firebase, Dart natif) en AppException.
/// Point d'entrée unique pour le mapping d'erreurs dans toute l'app.
class ErrorMapper {
  ErrorMapper._();

  static AppException map(Object error) {
    if (error is AppException) return error;

    if (error is FirebaseAuthException) {
      return AuthException.fromFirebaseCode(error.code);
    }

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return PermissionFirestoreException(error);
      }
      if (error.code == 'unavailable') {
        return NetworkException(error);
      }
      return UnknownException(error);
    }

    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('connexion')) {
      return NetworkException(error);
    }
    if (msg.contains('permission') && msg.contains('gps')) {
      return PermissionDeniedException('GPS', error);
    }

    return UnknownException(error);
  }

  /// Message utilisateur prêt à afficher (pour SnackBar).
  static String userMessage(Object error) => map(error).message;
}
