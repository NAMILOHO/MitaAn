/// Exception de base de l'application.
/// Toutes les exceptions métier héritent de celle-ci.
sealed class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => message;
}

// -----------------------------------------
// RESEAU
// -----------------------------------------
class NetworkException extends AppException {
  const NetworkException([Object? cause])
    : super('Pas de connexion internet. Vérifiez votre réseau.', cause);
}

// -----------------------------------------
// PERMISSIONS (GPS, Caméra, Stockage)
// -----------------------------------------
class PermissionDeniedException extends AppException {
  final String permissionType;

  const PermissionDeniedException(this.permissionType, [Object? cause])
    : super(
        'Permission $permissionType refusée. '
        'Activez-la dans les paramètres de l\'application.',
        cause,
      );
}

class LocationServiceDisabledException extends AppException {
  const LocationServiceDisabledException([Object? cause])
    : super('Le GPS est désactivé. Activez-le dans les paramètres.', cause);
}

// -----------------------------------------
// AUTHENTIFICATION
// -----------------------------------------
class AuthException extends AppException {
  final String code;

  const AuthException(this.code, String message, [Object? cause])
    : super(message, cause);

  factory AuthException.fromFirebaseCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return AuthException(code, 'Cet email est déjà utilisé');
      case 'wrong-password':
        return AuthException(code, 'Mot de passe incorrect');
      case 'user-not-found':
        return AuthException(code, 'Aucun compte avec cet email');
      case 'invalid-email':
        return AuthException(code, 'Adresse email invalide');
      case 'weak-password':
        return AuthException(
          code,
          'Le mot de passe est trop faible (minimum 6 caractères)',
        );
      case 'network-request-failed':
        return AuthException(code, 'Pas de connexion internet');
      case 'too-many-requests':
        return AuthException(code, 'Trop de tentatives. Réessayez plus tard');
      case 'requires-recent-login':
        return AuthException(code, 'Veuillez vous reconnecter pour continuer');
      default:
        return AuthException(code, 'Une erreur est survenue. Réessayez');
    }
  }
}

class SessionExpiredException extends AppException {
  const SessionExpiredException([Object? cause])
    : super('Votre session a expiré. Veuillez vous reconnecter.', cause);
}

// -----------------------------------------
// FIRESTORE / DONNÉES
// -----------------------------------------
class DataNotFoundException extends AppException {
  const DataNotFoundException(String entity, [Object? cause])
    : super('$entity introuvable.', cause);
}

class PermissionFirestoreException extends AppException {
  const PermissionFirestoreException([Object? cause])
    : super('Vous n\'avez pas la permission d\'effectuer cette action.', cause);
}

class ValidationException extends AppException {
  const ValidationException(super.message, [super.cause]);
}

// -----------------------------------------
// UPLOAD / FICHIERS
// -----------------------------------------
class FileTooLargeException extends AppException {
  final double sizeMb;

  FileTooLargeException(this.sizeMb, [Object? cause])
    : super(
        'Fichier trop volumineux (${sizeMb.toStringAsFixed(1)} MB). '
        'Maximum 5 MB.',
        cause,
      );
}

class UploadFailedException extends AppException {
  const UploadFailedException([Object? cause])
    : super('L\'envoi a echoue. Verifiez votre connexion et reessayez.', cause);
}

// -----------------------------------------
// GÉNÉRIQUE (fallback)
// -----------------------------------------
class UnknownException extends AppException {
  const UnknownException([Object? cause])
    : super('Une erreur inattendue est survenue.', cause);
}
