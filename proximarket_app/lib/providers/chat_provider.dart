import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider global pour les messages non lus.
/// Affiché comme badge sur l'onglet Messages de la bottom navbar.
class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Map chatId → nombre de messages non lus
  final Map<String, int> _unreadCounts = {};

  int get totalUnread =>
      _unreadCounts.values.fold(0, (a, b) => a + b);

  // ─────────────────────────────────────────
  // ÉCOUTER LES CONVERSATIONS EN TEMPS RÉEL
  // Appeler depuis AuthWrapper ou HomeScreen.initState()
  // ─────────────────────────────────────────
  Stream<int> watchTotalUnread(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final lastSenderId = data['lastSenderId'] as String? ?? '';
        if (lastSenderId != uid) {
          final unread = (data['unreadCount'] as num?)?.toInt() ?? 0;
          total += unread;
          _unreadCounts[doc.id] = unread;
        }
      }
      return total;
    });
  }

  void setUnread(String chatId, int count) {
    _unreadCounts[chatId] = count;
    notifyListeners();
  }

  void clearUnread(String chatId) {
    _unreadCounts[chatId] = 0;
    notifyListeners();
  }
}