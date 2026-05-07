import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

// ─────────────────────────────────────────
// HANDLER BACKGROUND — doit être top-level
// ─────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('📩 Message background: ${message.messageId}');
}

class NotificationService {
  // Singleton
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Canal Android
  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'proximarket_channel',
    'ProxiMarket Notifications',
    description: 'Notifications de ProxiMarket',
    importance: Importance.high,
    playSound: true,
  );

  // ─────────────────────────────────────────
  // INITIALISER
  // ─────────────────────────────────────────
  Future<void> initialize() async {
    // 1. Enregistrer handler background
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // 2. Demander permission
    await _requestPermission();

    // 3. Config notifications locales
    await _setupLocalNotifications();

    // 4. Écouter messages foreground
    _listenForeground();
  }

  // ─────────────────────────────────────────
  // DEMANDER PERMISSION
  // ─────────────────────────────────────────
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔔 Permission: ${settings.authorizationStatus}');
  }

  // ─────────────────────────────────────────
  // CONFIG NOTIFICATIONS LOCALES (version corrigée)
  // ─────────────────────────────────────────
  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Créer le canal Android — tout sur une ligne pour éviter l'erreur de retour à la ligne
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(_channel);
  }

  // ─────────────────────────────────────────
  // ÉCOUTER MESSAGES EN PREMIER PLAN
  // ─────────────────────────────────────────
  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'ProxiMarket',
          body: notification.body ?? '',
          payload: message.data['chatId'] ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification cliquée: ${message.data}');
      // Tu peux ajouter ici une navigation selon le type de notification
    });
  }

  // ─────────────────────────────────────────
  // AFFICHER UNE NOTIFICATION LOCALE
  // ─────────────────────────────────────────
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String payload = '',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'proximarket_channel',
      'ProxiMarket Notifications',
      channelDescription: 'Notifications ProxiMarket',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notifDetails,
      payload: payload,
    );
  }

  // ─────────────────────────────────────────
  // SAUVEGARDER TOKEN FCM DANS FIRESTORE
  // ─────────────────────────────────────────
  Future<void> saveTokenToFirestore(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': token});
        debugPrint('✅ Token FCM sauvegardé');
      }

      // Écouter renouvellement du token
      _messaging.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmToken': newToken});
        debugPrint('🔄 Token FCM renouvelé');
      });
    } catch (e) {
      debugPrint('❌ Erreur token FCM: $e');
    }
  }

  // ─────────────────────────────────────────
  // CRÉER UNE DEMANDE DE NOTIFICATION
  // ─────────────────────────────────────────
  Future<void> sendNotificationRequest({
    required String toUid,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications_queue')
          .add({
        'toUid': toUid,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });
    } catch (e) {
      debugPrint('❌ Erreur notification: $e');
    }
  }
}