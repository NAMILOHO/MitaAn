import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/history_service.dart';        // ← Import ajouté
import '../../utils/distance_helper.dart';
import '../chat/chat_screen.dart';
import '../profile/public_profile_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceModel service;
  final double? distanceKm;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    this.distanceKm,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final UserService _userService = UserService();
  UserModel? _owner;
  bool _isLoadingOwner = true;
  int _photoIndex = 0;

  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _loadOwner();

    // ====================== Ajout historique ======================
    HistoryService().addToHistory(widget.service.id);
    // ===============================================================
  }

  Future<void> _loadOwner() async {
    final owner = await _userService.getUserProfile(widget.service.userId);
    if (mounted) {
      setState(() {
        _owner = owner;
        _isLoadingOwner = false;
      });
    }
  }

  // ====================== Appeler & WhatsApp ======================
  Future<void> _callOwner() async {
    if (_owner == null || _owner!.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone non disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: _owner!.phone);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de passer l\'appel'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _whatsappOwner() async {
    if (_owner == null || _owner!.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone non disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String phone = _owner!.phone
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('+', '');

    if (!phone.startsWith('225') && phone.length <= 10) {
      phone = '225$phone';
    }

    final message = Uri.encodeComponent(
      'Bonjour, je vous contacte via ProxiMarket concernant votre annonce : ${widget.service.titre}',
    );

    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp n\'est pas installé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool get _isMyService {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == widget.service.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // AppBar avec photos (inchangé)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.service.photos.isNotEmpty
                  ? Stack(
                      children: [
                        PageView.builder(
                          itemCount: widget.service.photos.length,
                          onPageChanged: (i) => setState(() => _photoIndex = i),
                          itemBuilder: (_, i) => Image.network(
                            widget.service.photos[i],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _placeholder(),
                          ),
                        ),
                        if (widget.service.photos.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                widget.service.photos.length,
                                (i) => Container(
                                  width: i == _photoIndex ? 20 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: i == _photoIndex ? Colors.white : Colors.white54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : _placeholder(),
            ),
          ),

          // Contenu principal (inchangé)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + Catégorie
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.service.titre,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.service.categorie,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Prix + Distance
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          widget.service.prix > 0
                              ? '${widget.service.prix.toStringAsFixed(0)} FCFA'
                              : 'Prix à négocier',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (widget.distanceKm != null) ...[
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(DistanceHelper.format(widget.distanceKm!),
                            style: const TextStyle(color: Colors.grey)),
                      ] else if (widget.service.ville.isNotEmpty) ...[
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(widget.service.ville, style: const TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text('Description', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    widget.service.description,
                    style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                  ),
                  const SizedBox(height: 20),

                  // Profil du prestataire
                  const Text('Le prestataire', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isLoadingOwner
                        ? const Center(child: CircularProgressIndicator(color: primaryColor))
                        : _owner == null
                            ? const Text('Profil indisponible')
                            : Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: const Color(0xFFE0F2EE),
                                    backgroundImage: _owner!.photoUrl.isNotEmpty
                                        ? NetworkImage(_owner!.photoUrl)
                                        : null,
                                    child: _owner!.photoUrl.isEmpty
                                        ? Text(
                                            _owner!.nom.isNotEmpty ? _owner!.nom[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PublicProfileScreen(
                                                userId: widget.service.userId,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            _owner!.nom,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              decoration: TextDecoration.underline,
                                              color: Color(0xFF1D9E75),
                                            ),
                                          ),
                                        ),
                                        if (_owner!.isPro)
                                          Text(
                                            _owner!.categorie,
                                            style: const TextStyle(color: primaryColor, fontSize: 12),
                                          ),
                                        if (_owner!.bio.isNotEmpty)
                                          Text(
                                            _owner!.bio,
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isMyService ? _myServiceBar() : _contactBar(),
    );
  }

  // Méthodes _myServiceBar, _contactBar et _placeholder restent identiques
  Widget _myServiceBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.grey),
          const SizedBox(width: 8),
          const Expanded(child: Text('C\'est votre annonce', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _contactBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _callOwner,
                  icon: const Icon(Icons.phone, color: primaryColor),
                  label: const Text('Appeler', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _whatsappOwner,
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _owner != null
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(otherUser: _owner!)),
                      )
                  : null,
              icon: const Icon(Icons.message_outlined, color: Colors.white),
              label: const Text('Messagerie ProxiMarket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8F5F0),
      child: const Center(child: Icon(Icons.image_outlined, size: 64, color: Color(0xFF1D9E75))),
    );
  }
}