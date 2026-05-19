import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // GÉNÉRER UN ID DE CONVERSATION UNIQUE
  // L'ID est toujours le même pour 2 utilisateurs
  // ─────────────────────────────────────────
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // ─────────────────────────────────────────
  // ENVOYER UN MESSAGE
  // ─────────────────────────────────────────
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
    String senderName = '',
  }) async {
    final chatId = getChatId(senderId, receiverId);
    final now = FieldValue.serverTimestamp();

    // 1. Ajouter le message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc()
        .set({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': now,
      'isRead': false,
    });

    // 2. Mettre à jour la conversation
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [senderId, receiverId],
      'lastMessage': text,
      'lastMessageTime': now,
      'lastSenderId': senderId,
      'unreadCount': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // 3. Demande de notification
    await NotificationService().sendNotificationRequest(
      toUid: receiverId,
      title: senderName.isNotEmpty
          ? senderName
          : 'Nouveau message',
      body: text,
      data: {
        'type': 'message',
        'chatId': chatId,
        'senderId': senderId,
      },
    );
  }

  // ─────────────────────────────────────────
  // ÉCOUTER LES MESSAGES EN TEMPS RÉEL
  // ─────────────────────────────────────────
  Stream<List<MessageModel>> getMessages(String uid1, String uid2) {
    final chatId = getChatId(uid1, uid2);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) =>
                    MessageModel.fromMap(doc.data(), doc.id),
              )
              .toList(),
        );
  }

  // ─────────────────────────────────────────
  // RÉCUPÉRER TOUTES LES CONVERSATIONS
  // ─────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getConversations(
    String uid,
  ) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => {
                  'id': doc.id,
                  ...doc.data(),
                },
              )
              .toList(),
        );
  }

  // ─────────────────────────────────────────
  // MARQUER LES MESSAGES COMME LUS
  // ─────────────────────────────────────────
  Future<void> markAsRead(
    String chatId,
    String currentUserId,
  ) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where(
          'receiverId',
          isEqualTo: currentUserId,
        )
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (final doc in messages.docs) {
      batch.update(doc.reference, {
        'isRead': true,
      });
    }

    await batch.commit();

    // Remettre le compteur à 0
    await _firestore
        .collection('chats')
        .doc(chatId)
        .update({
      'unreadCount': 0,
    });
  }
}