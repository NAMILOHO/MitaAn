import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../services/user_service.dart';
import '../../services/service_firestore.dart';
import '../services/service_detail_screen.dart';
import '../chat/chat_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UserService _userService = UserService();
  final ServiceFirestore _serviceFirestore = ServiceFirestore();

  UserModel? _user;
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _userService.getUserProfile(widget.userId);
      final services = await _serviceFirestore.getUserServices(widget.userId);
      final activeServices = services.where((s) => s.isActive).toList();

      if (mounted) {
        setState(() {
          _user = user;
          _services = activeServices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signaler() async {
    final raison = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? selected;
        return StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            title: const Text('Signaler ce profil'),
            content: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              hint: const Text('Choisir une raison'),
              items: ['Spam', 'Contenu inapproprié', 'Fausse annonce', 'Autre']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setD(() => selected = v),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: selected != null
                    ? () => Navigator.pop(ctx, selected)
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Signaler',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );

    if (raison != null && mounted) {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterId': FirebaseAuth.instance.currentUser?.uid,
        'targetId': widget.userId,
        'raison': raison,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil signalé. Merci.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('Profil introuvable')),
      );
    }

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = myUid == widget.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(_user!.nom),
        actions: [
          if (!isMe)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'signaler') _signaler();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'signaler',
                  child: Text('Signaler ce profil'),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête profil
            Container(
              width: double.infinity,
              color: primaryColor,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _user!.photoUrl.isNotEmpty
                        ? NetworkImage(_user!.photoUrl)
                        : null,
                    child: _user!.photoUrl.isEmpty
                        ? Text(
                            _user!.nom.isNotEmpty
                                ? _user!.nom[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 36,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user!.nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_user!.isPro && _user!.categorie.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2), // ← Corrigé
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _user!.categorie,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                  if (_user!.ville.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _user!.ville,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                  if (_user!.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Membre depuis ${_formatDate(_user!.createdAt!)}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),

            // Stats
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statItem('${_services.length}', 'Annonces actives'),
                ],
              ),
            ),

            // Bio
            if (_user!.bio.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'À propos',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user!.bio,
                      style: const TextStyle(
                          color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),

            // Bouton contacter
            if (!isMe)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(otherUser: _user!),
                      ),
                    ),
                    icon: const Icon(Icons.message_outlined,
                        color: Colors.white),
                    label: const Text('Envoyer un message',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

            // Annonces
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Ses annonces',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  Text(
                    '${_services.length}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            if (_services.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Aucune annonce publiée',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: _services.length,
                itemBuilder: (_, i) => _buildServiceTile(_services[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildServiceTile(ServiceModel service) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(service: service),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06), // ← Corrigé
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: service.photos.isNotEmpty
                  ? Image.network(
                      service.photos.first,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.titre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.prix > 0
                        ? '${service.prix.toStringAsFixed(0)} FCFA'
                        : 'Négociable',
                    style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: const Color(0xFFE8F5F0),
      child: const Icon(Icons.image_outlined,
          color: primaryColor, size: 32),
    );
  }

  String _formatDate(DateTime dt) {
    const mois = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${mois[dt.month]} ${dt.year}';
  }
}