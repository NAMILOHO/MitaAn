import 'dart:async';
import 'package:flutter/foundation.dart'; // Import requis pour PlatformDispatcher
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/service_provider.dart';
import 'providers/category_provider.dart';        // ← AJOUTÉ
import 'services/notification_service.dart';
import 'services/presence_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/offline_banner.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================
  // ORIENTATION BLOQUÉE
  // =========================
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // =========================
  // INITIALISATION FIREBASE
  // =========================
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // =========================
  // PERSISTENCE OFFLINE FIRESTORE
  // =========================
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // =========================
  // CRASHLYTICS FLUTTER ERRORS
  // =========================
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // =========================
  // CRASHLYTICS PLATFORM ERRORS
  // =========================
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    );
    return true;
  };

  // =========================
  // INITIALISATION NOTIFICATIONS
  // =========================
  await NotificationService().initialize();
  PresenceService().init();

  // =========================
  // LANCEMENT APPLICATION (ZONÉ)
  // =========================
  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) => FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    ),
  );
}

// ======================================================
// APP PRINCIPALE
// ======================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => app_auth.AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ServiceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(),   // ← AJOUTÉ
        ),
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'ProxiMarket',
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF1D9E75),
                  ),
                  scaffoldBackgroundColor: Colors.white,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                    foregroundColor: Colors.black,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF1D9E75),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                home: const SplashScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// AUTH WRAPPER
// ======================================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // =========================
        // CHARGEMENT
        // =========================
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1D9E75),
              ),
            ),
          );
        }

        // =========================
        // UTILISATEUR CONNECTÉ
        // =========================
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          // Sauvegarde token FCM
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await NotificationService().initialize();
              await NotificationService().saveTokenToFirestore(user.uid);
              debugPrint('✅ FCM Token sauvegardé pour ${user.uid}');
            } catch (e, stack) {
              debugPrint('❌ Erreur FCM : $e');
              FirebaseCrashlytics.instance.recordError(
                e,
                stack,
              );
            }
          });
          return const HomeScreen();
        }

        // =========================
        // UTILISATEUR NON CONNECTÉ
        // =========================
        return const LoginScreen();
      },
    );
  }
}
