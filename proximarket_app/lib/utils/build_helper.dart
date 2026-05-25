import 'package:flutter/foundation.dart';

class BuildHelper {
  BuildHelper._();

  static bool get isDebug => kDebugMode;
  static bool get isRelease => kReleaseMode;

  static void log(String message) {
    if (kDebugMode) debugPrint('[MitaAn] $message');
  }

  static const String version = '1.0.0-beta';
  static const String buildNumber = '1';
}
