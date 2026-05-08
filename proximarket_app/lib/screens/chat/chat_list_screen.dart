import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';

import '../services/services_list_screen.dart'; // ✅ AJOUT
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final ChatService chatService = ChatService();
    final UserService userService = UserService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getConversations(myUid),
        builder: (context, snapshot) {
          // ───────── LOADING ─────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          final conversations = snapshot.data ?? [];

          // ───────── EMPTY STATE (CORRIGÉ) ─────────
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 80, color: Colors.grey),

                    const SizedBox(height: 16),

                    const Text(
                      'Aucune conversation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Contactez un prestataire pour démarrer une discussion.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 24),

                    // ✅ BOUTON AJOUTÉ
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServicesListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Explorer les services'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // ───────── LISTE DES CONVERSATIONS ─────────
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];

              final participants =
                  List<String>.from(conv['participants'] ?? []);

              final otherUid = participants.firstWhere(
                (id) => id != myUid,
                orElse: () => '',
              );

              if (otherUid.isEmpty) return const SizedBox();

              return FutureBuilder<UserModel?>(
                future: userService.getUserProfile(otherUid),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const SizedBox(height: 72);
                  }

                  final otherUser = userSnap.data!;

                  final lastMessage = conv['lastMessage'] ?? '';
                  final unread = conv['unreadCount'] ?? 0;
                  final lastSenderId = conv['lastSenderId'] ?? '';
                  final isLastMine = lastSenderId == myUid;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatScreen(otherUser: otherUser),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ───── AVATAR ─────
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFE0F2EE),
                            backgroundImage:
                                otherUser.photoUrl.isNotEmpty
                                    ? NetworkImage(otherUser.photoUrl)
                                    : null,
                            child: otherUser.photoUrl.isEmpty
                                ? Text(
                                    otherUser.nom.isNotEmpty
                                        ? otherUser.nom[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),

                          const SizedBox(width: 12),

                          // ───── INFOS ─────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  otherUser.nom,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isLastMine
                                      ? 'Vous : $lastMessage'
                                      : lastMessage,
                                  style: TextStyle(
                                    color: unread > 0 && !isLastMine
                                        ? Colors.black87
                                        : Colors.grey,
                                    fontWeight: unread > 0 && !isLastMine
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // ───── BADGE ─────
                          if (unread > 0 && !isLastMine)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unread.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}