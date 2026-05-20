import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/history_service.dart';
import '../../utils/distance_helper.dart';
import '../../utils/geo_utils.dart';
import '../chat/chat_screen.dart';
import '../profile/public_profile_screen.dart';

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
  static const whatsapp     = Color(0xFF25D366);

  static const catColors = <String, Color>{
    'Artisan'    : Color(0xFF085041),
    'Artiste'    : Color(0xFF27500A),
    'Éleveur'    : Color(0xFF633806),
    'Commerçant' : Color(0xFF0C447C),
    'Commerce'   : Color(0xFF0C447C),
    'Plombier'   : Color(0xFF3C3489),
    'Électricien': Color(0xFF72243E),
    'Menuisier'  : Color(0xFF4A1B0C),
    'Autre'      : Color(0xFF444441),
  };
  static const catBg = <String, Color>{
    'Artisan'    : Color(0xFFE1F5EE),
    'Artiste'    : Color(0xFFEAF3DE),
    'Éleveur'    : Color(0xFFFAEEDA),
    'Commerçant' : Color(0xFFE6F1FB),
    'Commerce'   : Color(0xFFE6F1FB),
    'Plombier'   : Color(0xFFEEEDFE),
    'Électricien': Color(0xFFFBEAF0),
    'Menuisier'  : Color(0xFFFAEEDA),
    'Autre'      : Color(0xFFF1EFE8),
  };
  static Color catColor(String c) => catColors[c] ?? primary;
  static Color catBgColor(String c) => catBg[c] ?? primaryLight;
}

// ─────────────────────────────────────────────────
// ÉCRAN
// ─────────────────────────────────────────────────
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

  @override
  void initState() {
    super.initState();
    _loadOwner();
    HistoryService().addToHistory(widget.service.id);
  }

  Future<void> _loadOwner() async {
    final owner = await _userService.getUserProfile(widget.service.userId);
    if (mounted) setState(() { _owner = owner; _isLoadingOwner = false; });
  }

  bool get _isMyService =>
      FirebaseAuth.instance.currentUser?.uid == widget.service.userId;

  Future<void> _callOwner() async {
    if (_owner == null || _owner!.phone.isEmpty) {
      _snack('Numéro de téléphone non disponible', Colors.orange);
      return;
    }
    try {
      await launchUrl(Uri(scheme: 'tel', path: _owner!.phone));
    } catch (_) {
      _snack('Impossible de passer l\'appel', Colors.red);
    }
  }

  Future<void> _whatsappOwner() async {
    if (_owner == null || _owner!.phone.isEmpty) {
      _snack('Numéro de téléphone non disponible', Colors.orange);
      return;
    }
    String phone = _owner!.phone
        .replaceAll(' ', '').replaceAll('-', '').replaceAll('+', '');
    if (!phone.startsWith('225') && phone.length <= 10) phone = '225$phone';
    final msg = Uri.encodeComponent(
      'Bonjour, je vous contacte via MitaAn concernant : ${widget.service.titre}',
    );
    try {
      await launchUrl(
        Uri.parse('https://wa.me/$phone?text=$msg'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      _snack('WhatsApp n\'est pas installé', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildHero(),
                SliverToBoxAdapter(child: _buildContent()),
              ],
            ),
          ),
          _isMyService ? _buildMyServiceBar() : _buildCTABar(),
        ],
      ),
    );
  }

  // ── HERO ──
  Widget _buildHero() {
    final photos = widget.service.photos;
    final catBg  = _T.catBgColor(widget.service.categorie);
    final catCol = _T.catColor(widget.service.categorie);

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _T.textPrimary),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border_rounded, size: 20, color: _T.textSecondary),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: photos.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _photoIndex = i),
                    itemBuilder: (_, i) => Image.network(
                      photos[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(catBg, catCol),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 14,
                      left: 0, right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(photos.length, (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _photoIndex ? 18 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: i == _photoIndex
                                ? _T.primary
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                      ),
                    ),
                ],
              )
            : _photoPlaceholder(catBg, catCol),
      ),
    );
  }

  Widget _photoPlaceholder(Color bg, Color color) {
    return Container(
      color: bg,
      child: Center(child: Icon(Icons.image_outlined, color: color, size: 56)),
    );
  }

  // ── CONTENU ──
  Widget _buildContent() {
    final catColor = _T.catColor(widget.service.categorie);
    final catBg    = _T.catBgColor(widget.service.categorie);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge catégorie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: catBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              widget.service.categorie,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: catColor,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Titre
          Text(
            widget.service.titre,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),

          // Prix + distance
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.service.prix > 0
                      ? '${widget.service.prix.toStringAsFixed(0)} FCFA'
                      : 'Prix à négocier',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (widget.service.unite.isNotEmpty && widget.service.unite != 'forfait') ...[
                const SizedBox(width: 8),
                Text(
                  '/ ${widget.service.unite}',
                  style: const TextStyle(fontSize: 12, color: _T.textSecondary),
                ),
              ],
              const Spacer(),
              if (widget.distanceKm != null) ...[
                const Icon(Icons.location_on_rounded, size: 13, color: _T.textTertiary),
                const SizedBox(width: 3),
                Text(
                  GeoUtils.formatDistance(widget.distanceKm!),
                  style: const TextStyle(fontSize: 12, color: _T.textTertiary),
                ),
                const SizedBox(width: 6),
                _proximityBadge(widget.distanceKm!),
              ] else if (widget.service.ville.isNotEmpty) ...[
                const Icon(Icons.location_on_rounded, size: 13, color: _T.textTertiary),
                const SizedBox(width: 3),
                Text(
                  widget.service.ville.split(',').first,
                  style: const TextStyle(fontSize: 12, color: _T.textTertiary),
                ),
              ],
            ],
          ),

          const _Divider(),

          // Description
          const Text(
            'Description',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _T.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.service.description,
            style: const TextStyle(
              fontSize: 13,
              color: _T.textSecondary,
              height: 1.65,
            ),
          ),

          const _Divider(),

          // Prestataire
          const Text(
            'Le prestataire',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _T.textPrimary),
          ),
          const SizedBox(height: 10),
          _buildOwnerCard(),
        ],
      ),
    );
  }

  Widget _buildOwnerCard() {
    if (_isLoadingOwner) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2),
        ),
      );
    }
    if (_owner == null) {
      return const Text('Profil indisponible', style: TextStyle(color: _T.textSecondary));
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: widget.service.userId)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _T.primaryLight,
                image: _owner!.photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_owner!.photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _owner!.photoUrl.isEmpty
                  ? Center(
                      child: Text(
                        _owner!.nom.isNotEmpty ? _owner!.nom[0].toUpperCase() : '?',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _T.primaryDark,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _owner!.nom,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _T.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (_owner!.isPro && _owner!.categorie.isNotEmpty) ...[
                        Text(
                          _owner!.categorie,
                          style: const TextStyle(fontSize: 11, color: _T.primary),
                        ),
                        if (_owner!.ville.isNotEmpty)
                          const Text(' • ', style: TextStyle(fontSize: 11, color: _T.textTertiary)),
                      ],
                      if (_owner!.ville.isNotEmpty)
                        Text(
                          _owner!.ville.split(',').first,
                          style: const TextStyle(fontSize: 11, color: _T.textTertiary),
                        ),
                    ],
                  ),
                  if (_owner!.bio.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      _owner!.bio,
                      style: const TextStyle(fontSize: 11, color: _T.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _T.border),
              ),
              child: const Icon(Icons.chevron_right_rounded, size: 18, color: _T.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ── BARRE CTA ──
  Widget _buildCTABar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _T.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _ctaButton(
                  label: 'Appeler',
                  icon: Icons.phone_rounded,
                  color: _T.primary,
                  outlined: true,
                  onTap: _callOwner,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ctaButton(
                  label: 'WhatsApp',
                  icon: Icons.chat_rounded,
                  color: _T.whatsapp,
                  outlined: false,
                  onTap: _whatsappOwner,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ctaButton(
            label: 'Messagerie MitaAn',
            icon: Icons.message_outlined,
            color: _T.primary,
            outlined: false,
            fullWidth: true,
            onTap: _owner != null
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(otherUser: _owner!)),
                    )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _ctaButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool outlined,
    bool fullWidth = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: outlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(13),
          border: outlined ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: outlined ? color : Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: outlined ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyServiceBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _T.border, width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: _T.textTertiary, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'C\'est votre annonce',
              style: TextStyle(color: _T.textSecondary, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _T.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retour',
                style: TextStyle(
                  color: _T.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _proximityBadge(double km) {
    Color color; Color bg; String label;
    if (km <= 2)       { color = const Color(0xFF085041); bg = const Color(0xFFE1F5EE); label = 'Très proche'; }
    else if (km <= 10) { color = const Color(0xFF633806); bg = const Color(0xFFFAEEDA); label = 'Proche'; }
    else               { color = const Color(0xFF444441); bg = const Color(0xFFF1EFE8); label = 'Éloigné'; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Divider(height: 0.5, color: _T.border),
  );
}