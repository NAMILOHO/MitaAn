class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'MitaAn';
  static const String appVersion = '1.0.0';

  // Couleurs
  static const int primaryColorValue = 0xFF1D9E75;

  // Firestore collections
  static const String colUsers = 'users';
  static const String colServices = 'services';
  static const String colChats = 'chats';
  static const String colMessages = 'messages';
  static const String colReviews = 'reviews';
  static const String colReports = 'reports';
  static const String colNotifQueue = 'notifications_queue';

  // Limites
  static const int maxPhotosPerService = 4;
  static const int maxBioLength = 200;
  static const int maxTitleLength = 100;
  static const int minTitleLength = 5;
  static const int minDescLength = 20;
  static const int maxHistoryItems = 10;
  static const int paginationLimit = 10;
  static const double defaultRadiusKm = 20.0;

  // Image
  static const int imageMaxWidthPx = 800;
  static const int imageMaxHeightPx = 800;
  static const int imageQualityPercent = 70;
  static const int profileImageSizePx = 400;
  static const int maxImageSizeMb = 5;
}
