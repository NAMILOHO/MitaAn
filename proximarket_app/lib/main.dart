import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/service_provider.dart';
import 'providers/chat_provider.dart'; // ← AJOUT
import 'services/notification_service.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/chat/chat_list_screen.dart'; // ← AJOUT pour route /chat

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  await NotificationService().initialize();

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) => FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      fatal: true,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()), // ← AJOUT
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'MitaAn', // ✅ CORRECTION : était 'ProxiMarket'
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D9E75),
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        // ✅ AJOUT : route pour la navigation depuis les notifications push
        routes: {
          '/chat': (ctx) {
            final args = ModalRoute.of(ctx)?.settings.arguments
                as Map<String, dynamic>?;
            // args contient 'chatId', 'senderId' depuis la notification
            return const ChatListScreen();
          },
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// AUTH WRAPPER
// ─────────────────────────────────────────
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1D9E75),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService().saveTokenToFirestore(
              snapshot.data!.uid,
            );
          });
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}