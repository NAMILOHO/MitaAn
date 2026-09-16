import 'package:flutter/material.dart';

/// Design System MitaAn — source unique de vérité.
/// N'écrase pas AppColors (legacy, encore utilisé par login/register/edit_profile).
class AppTheme {
  AppTheme._();

  // ── Couleurs de base ──
  static const Color primary = Color(0xFF1D9E75);
  static const Color primaryDark = Color(0xFF085041);
  static const Color primaryLight = Color(0xFFE1F5EE);
  static const Color bg = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0D1117);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFFB0B7C3);
  static const Color border = Color(0xFFEEEEF2);

  // ── États ──
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color whatsapp = Color(0xFF25D366);

  // ── Espacements (échelle 4pt) ──
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  // ── Border radius ──
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 999;

  // ── Ombres ──
  static List<BoxShadow> get shadowSubtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowFloat => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowColored(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Typographie ──
  static const TextStyle displayL = TextStyle(
    fontSize: 27,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle bodyL = TextStyle(fontSize: 14, color: textPrimary);
  static const TextStyle body = TextStyle(fontSize: 13, color: textSecondary);
  static const TextStyle bodyS = TextStyle(fontSize: 12, color: textSecondary);
  static const TextStyle caption = TextStyle(fontSize: 11, color: textTertiary);

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: textSecondary,
    letterSpacing: 0.4,
  );

  // ── Boutons ──
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: textTertiary.withValues(alpha: 0.3),
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      );

  static ButtonStyle get outlinedButton => OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      );

  // ── Décorations cartes ──
  static BoxDecoration card({Color? bgColor, bool elevated = false}) {
    return BoxDecoration(
      color: bgColor ?? surface,
      borderRadius: BorderRadius.circular(radiusLg),
      border: elevated ? null : Border.all(color: border, width: 0.5),
      boxShadow: elevated ? shadowSubtle : null,
    );
  }
}
