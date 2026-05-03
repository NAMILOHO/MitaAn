import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

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
  int _currentPhotoIndex = 0;

  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _loadOwner();
  }

  Future<void> _loadOwner() async {
    final owner = await _userService.getUserProfile(widget.service.userId);
    setState(() {
      _owner = owner;
      _isLoadingOwner = false;
    });
  }

  Future<void> _callOwner() async {
    if (_owner == null || _owner!.phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: _owner!.phone);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsappOwner() async {
    if (_owner == null || _owner!.phone.isEmpty) return;

    final phone = _owner!.phone.replaceAll(RegExp(r'\D'), '');
    final message = Uri.encodeComponent(
        'Bonjour, je suis intéressé par votre service "${widget.service.titre}"');

    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _isMyService {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == widget.service.userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [

          /// 🔝 APPBAR AVEC IMAGES
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.service.photos.isNotEmpty
                  ? PageView.builder(
                      itemCount: widget.service.photos.length,
                      onPageChanged: (i) =>
                          setState(() => _currentPhotoIndex = i),
                      itemBuilder: (_, i) => Image.network(
                        widget.service.photos[i],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholderImage(),
                      ),
                    )
                  : _placeholderImage(),
            ),
          ),

          /// 📄 CONTENU
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 🏷️ TITRE
                  Text(
                    widget.service.titre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 💰 PRIX
                  Text(
                    widget.service.prix > 0
                        ? '${widget.service.prix.toStringAsFixed(0)} FCFA'
                        : 'Prix à discuter',
                    style: const TextStyle(
                      fontSize: 18,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 📍 DISTANCE
                  if (widget.distanceKm != null)
                    Text(
                      '${widget.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(color: Colors.grey),
                    ),

                  const SizedBox(height: 20),

                  /// 📝 DESCRIPTION
                  const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(widget.service.description),

                  const SizedBox(height: 20),

                  /// 👤 VENDEUR
                  const Text(
                    "Prestataire",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  _isLoadingOwner
                      ? const CircularProgressIndicator()
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundImage:
                                  (_owner?.photoUrl.isNotEmpty ?? false)
                                      ? NetworkImage(_owner!.photoUrl)
                                      : null,
                              child: (_owner?.photoUrl.isEmpty ?? true)
                                  ? Text(_owner?.nom[0] ?? '?')
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(_owner?.nom ?? 'Utilisateur'),
                          ],
                        ),

                  const SizedBox(height: 30),

                  /// 📞 BOUTONS
                  if (!_isMyService)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _callOwner,
                            icon: const Icon(Icons.call),
                            label: const Text("Appeler"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _whatsappOwner,
                            icon: const Icon(Icons.message),
                            label: const Text("WhatsApp"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🖼️ IMAGE PAR DÉFAUT
  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),git
    );
  }
}