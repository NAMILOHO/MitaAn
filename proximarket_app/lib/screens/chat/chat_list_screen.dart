import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../widgets/online_indicator.dart';
import '../services/services_list_screen.dart';
import 'chat_screen.dart';

// ─────────────────────────────────────────────────
// THÈME
// ─────────────────────────────────────────────────
class _T {
  static const primary      = Color(0xFF1D9E75);
  static const primaryLight = Color(0xFFE1F5EE);
  static const primaryDark  = Color(0xFF085041);
  static const bg           = Color(0xFFF8F9FA);
  static const textPrimary  = Color(0xFF0D1117);
  static const textSecondary= Color(0xFF6B7280);
  static const textTertiary = Color(0xFFB0B7C3);
  static const border       = Color(0xFFEEEEF2);

  static const avatarColors = [
    [Color(0xFFE1F5EE), Color(0xFF085041)],
    [Color(0xFFEAF3DE), Color(0xFF27500A)],
    [Color(0xFFE6F1FB), Color(0xFF0C447C)],
    [Color(0xFFFBEAF0), Color(0xFF72243E)],
    [Color(0xFFFAEEDA), Color(0xFF633806)],
    [Color(0xFFEEEDFE), Color(0xFF3C3489)],
  ];

  static List<Color> avatarColor(String name) {
    if (name.isEmpty) return avatarColors[0];
    return avatarColors[name.codeUnitAt(0) % avatarColors.length];
  }
}

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Vous devez être connecté')),
      );
    }

    final String myUid = currentUser.uid;
    final ChatService chatService = ChatService();
    final UserService userService = UserService();

    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          _buildAppBar(),
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatService.getConversations(myUid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _T.primary, strokeWidth: 2,
                    ),
                  );
                }

                final conversations = snapshot.data ?? [];

                if (conversations.isEmpty) {
                  return _buildEmpty(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conv = conversations[index];
                    final participants = List<String>.from(conv['participants'] ?? []);
                    final otherUid = participants.firstWhere(
                      (id) => id != myUid,
                      orElse: () => '',
                    );

                    if (otherUid.isEmpty) return const SizedBox.shrink();

                    return FutureBuilder<UserModel?>(
                      future: userService.getUserProfile(otherUid),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || userSnap.data == null) {
                          return const SizedBox(height: 72);
                        }

                        final otherUser = userSnap.data!;
                        final lastMessage = conv['lastMessage']?.toString() ?? '';
                        final unread = (conv['unreadCount'] ?? 0) as int;
                        final lastSenderId = conv['lastSenderId']?.toString() ?? '';
                        final isLastMine = lastSenderId == myUid;

                        // Filtre recherche
                        if (_searchQuery.isNotEmpty &&
                            !otherUser.nom.toLowerCase().contains(_searchQuery)) {
                          return const SizedBox.shrink();
                        }

                        return _ConversationTile(
                          user: otherUser,
                          lastMessage: lastMessage,
                          unreadCount: unread,
                          isLastMine: isLastMine,
                          timestamp: conv['lastMessageTime'],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(otherUser: otherUser),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── APP BAR ──
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 20, right: 20, bottom: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── SEARCH BAR ──
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _T.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: _T.textTertiary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase().trim()),
                style: const TextStyle(fontSize: 13, color: _T.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Rechercher une conversation...',
                  hintStyle: TextStyle(fontSize: 13, color: _T.textTertiary),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.close_rounded, size: 16, color: _T.textTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.border),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: _T.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune conversation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _T.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Contactez un prestataire pour démarrer une discussion.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _T.textSecondary),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServicesListScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Explorer les services',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// TILE CONVERSATION
// ─────────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final UserModel user;
  final String lastMessage;
  final int unreadCount;
  final bool isLastMine;
  final dynamic timestamp;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
    required this.isLastMine,
    required this.timestamp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0 && !isLastMine;
    final colors = _T.avatarColor(user.nom);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[0],
                        image: user.photoUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(user.photoUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: user.photoUrl.isEmpty
                          ? Center(
                              child: Text(
                                user.nom.isNotEmpty
                                    ? user.nom[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: colors[1],
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: OnlineIndicator(userId: user.uid, size: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.nom,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _T.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: hasUnread ? _T.primary : _T.textTertiary,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isLastMine
                                  ? 'Vous : $lastMessage'
                                  : lastMessage,
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnread
                                    ? _T.textPrimary
                                    : _T.textSecondary,
                                fontWeight: hasUnread
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: _T.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 76),
          child: Divider(height: 0.5, color: _T.border),
        ),
      ],
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime? dt;
    try {
      dt = timestamp.toDate();
    } catch (_) {
      return '';
    }
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) {
      const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return jours[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}
