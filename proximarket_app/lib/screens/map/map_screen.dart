import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/location_service.dart';
import '../../models/user_model.dart';

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
  static const meColor      = Color(0xFF185FA5);

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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultPosition = LatLng(5.3600, -4.0083);

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  LatLng? _userPosition;
  List<UserModel> _pros = [];
  bool _isLoading = true;
  String? _errorMessage;

  double _radiusKm = 20.0;
  String? _selectedCategorie;
  UserModel? _selectedPro;

  static const List<double> _rayonOptions = [5, 10, 20, 50];

  static const List<String> _categories = [
    'Tous', 'Artisan', 'Artiste', 'Éleveur',
    'Commerçant', 'Plombier', 'Électricien', 'Menuisier', 'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final position = await _locationService.getCurrentPosition();
      _userPosition = LatLng(position.latitude, position.longitude);
      await _loadPros();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPros() async {
    if (_userPosition == null) return;
    try {
      final pros = await _locationService.getNearbyPros(
        myLat: _userPosition!.latitude,
        myLng: _userPosition!.longitude,
        radiusKm: _radiusKm,
        categorieFilter: _selectedCategorie == 'Tous' ? null : _selectedCategorie,
      );
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      if (mounted) {
        setState(() {
          _pros = pros.where((u) => u.uid != myUid).toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  void _recenter() {
    if (_userPosition != null) {
      _mapController.move(_userPosition!, _zoomForRadius(_radiusKm));
    }
  }

  double _zoomForRadius(double km) {
    if (km <= 5) return 14;
    if (km <= 10) return 13;
    if (km <= 20) return 12;
    return 10;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Marker utilisateur
    if (_userPosition != null) {
      markers.add(Marker(
        point: _userPosition!,
        width: 20,
        height: 20,
        child: Container(
          decoration: BoxDecoration(
            color: _T.meColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ));
    }

    // Markers prestataires
    for (final pro in _pros) {
      markers.add(Marker(
        point: LatLng(pro.gpsLat, pro.gpsLng),
        width: 120,
        height: 52,
        child: GestureDetector(
          onTap: () => setState(() => _selectedPro = pro),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pro.nom.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CustomPaint(
                size: const Size(10, 6),
                painter: _TrianglePainter(_T.primary),
              ),
            ],
          ),
        ),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
          _buildAppBar(),
          _buildRayonChips(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: _T.primary, strokeWidth: 2,
                    ),
                  )
                : _errorMessage != null
                    ? _buildError()
                    : Stack(
                        children: [
                          _buildMap(),
                          _buildCounter(),
                          _buildFAB(),
                          if (_selectedPro != null) _buildBottomSheet(),
                        ],
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
          Row(
            children: [
              const Text(
                'Carte',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              _iconBtn(
                icon: Icons.tune_rounded,
                active: _selectedCategorie != null,
                onTap: _showFiltersSheet,
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.refresh_rounded,
                onTap: _isLoading ? null : _initMap,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _iconBtn({required IconData icon, bool active = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: active ? _T.primaryLight : _T.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF9FE1CB) : _T.border),
        ),
        child: Icon(icon, size: 18, color: active ? _T.primary : _T.textSecondary),
      ),
    );
  }

  // ── CHIPS RAYON ──
  Widget _buildRayonChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: _rayonOptions.map((r) {
            final sel = _radiusKm == r;
            return GestureDetector(
              onTap: () {
                setState(() => _radiusKm = r);
                _loadPros();
                _recenter();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel ? _T.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? _T.primary : _T.border),
                ),
                child: Text(
                  '${r.toInt()} km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: sel ? Colors.white : _T.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── CARTE ──
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userPosition ?? _defaultPosition,
        initialZoom: _zoomForRadius(_radiusKm),
        minZoom: 5,
        maxZoom: 18,
        onTap: (_, __) => setState(() => _selectedPro = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.mitan.app',
        ),
        MarkerLayer(markers: _buildMarkers()),
      ],
    );
  }

  // ── COMPTEUR ──
  Widget _buildCounter() {
    return Positioned(
      bottom: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _T.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: _T.meColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('Moi', style: TextStyle(fontSize: 11, color: _T.textSecondary)),
            Container(
              width: 0.5, height: 14,
              color: _T.border,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: _T.primary, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              '${_pros.length} prestataire${_pros.length > 1 ? 's' : ''} (${_radiusKm.toInt()} km)',
              style: const TextStyle(fontSize: 11, color: _T.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB RECENTRER ──
  Widget _buildFAB() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: GestureDetector(
        onTap: _recenter,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _T.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // ── BOTTOM SHEET PRESTATAIRE ──
  Widget _buildBottomSheet() {
    final pro = _selectedPro!;
    final colors = _T.avatarColor(pro.nom);
    final distance = _userPosition != null
        ? _locationService.calculateDistance(
            _userPosition!.latitude, _userPosition!.longitude,
            pro.gpsLat, pro.gpsLng,
          )
        : null;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(top: BorderSide(color: _T.border, width: 0.5)),
        ),
        padding: EdgeInsets.fromLTRB(
          16, 12, 16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _T.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card prestataire
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[0],
                    image: pro.photoUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(pro.photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pro.photoUrl.isEmpty
                      ? Center(
                          child: Text(
                            pro.nom.isNotEmpty ? pro.nom[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colors[1],
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
                        pro.nom,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _T.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (pro.categorie.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _T.primaryLight,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                pro.categorie,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _T.primaryDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (distance != null) ...[
                            const Icon(Icons.location_on_rounded, size: 12, color: _T.textTertiary),
                            const SizedBox(width: 2),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 11, color: _T.textTertiary),
                            ),
                          ],
                        ],
                      ),
                      if (pro.ville.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          pro.ville.split(',').first,
                          style: const TextStyle(fontSize: 11, color: _T.textTertiary),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _T.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _T.border),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, size: 18, color: _T.textTertiary),
                ),
              ],
            ),

            if (pro.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                pro.bio,
                style: const TextStyle(fontSize: 12, color: _T.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── FILTRES ──
  void _showFiltersSheet() {
    String? tempCat = _selectedCategorie;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: _T.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filtrer par catégorie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final sel = tempCat == cat ||
                      (tempCat == null && cat == 'Tous');
                  return GestureDetector(
                    onTap: () => setSheet(() {
                      tempCat = cat == 'Tous' ? null : cat;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? _T.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? _T.primary : _T.border,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: sel ? Colors.white : _T.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedCategorie = tempCat);
                    _loadPros();
                  },
                  child: const Text(
                    'Appliquer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ERREUR ──
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.border),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 32,
                color: _T.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Erreur GPS',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _T.textSecondary),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _initMap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Réessayer',
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
// TRIANGLE PAINTER (pointe du marker)
// ─────────────────────────────────────────────────
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}