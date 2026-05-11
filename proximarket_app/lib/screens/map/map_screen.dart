import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/location_service.dart';
import '../../models/user_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Color primaryColor = Color(0xFF1D9E75);

  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();

  LatLng? _userPosition;
  List<UserModel> _pros = [];
  bool _isLoading = true;
  String? _errorMessage;

  final LatLng _defaultPosition = LatLng(5.3600, -4.0083);

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  // ─────────────────────────────────────────
  // INITIALISATION
  // ─────────────────────────────────────────
  Future<void> _initMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();

      _userPosition = LatLng(
        position.latitude,
        position.longitude,
      );

      await _loadPros();

      if (mounted && _userPosition != null) {
        _mapController.move(_userPosition!, 13);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────
  // CHARGER LES PRESTATAIRES
  // ─────────────────────────────────────────
  Future<void> _loadPros() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('isPro', isEqualTo: true)
        .get();

    final pros = snap.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .where((u) => u.gpsLat != 0.0 && u.gpsLng != 0.0)
        .toList();

    if (mounted) {
      setState(() {
        _pros = pros;
      });
    }
  }

  // ─────────────────────────────────────────
  // MARKERS
  // ─────────────────────────────────────────
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Position utilisateur
    if (_userPosition != null) {
      markers.add(
        Marker(
          point: _userPosition!,
          width: 50,
          height: 50,
          child: const Tooltip(
            message: 'Ma position',
            child: Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 36,
            ),
          ),
        ),
      );
    }

    // Prestataires
    for (final pro in _pros) {
      final isSelf =
          pro.uid == FirebaseAuth.instance.currentUser?.uid;

      if (isSelf) continue;

      markers.add(
        Marker(
          point: LatLng(pro.gpsLat, pro.gpsLng),
          width: 160,
          height: 60,
          child: GestureDetector(
            onTap: () => _showProBottomSheet(pro),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    pro.nom.split(' ').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.location_on,
                  color: primaryColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // ─────────────────────────────────────────
  // BOTTOM SHEET
  // ─────────────────────────────────────────
  void _showProBottomSheet(UserModel pro) {
    double? distance;

    if (_userPosition != null) {
      distance = _locationService.calculateDistance(
        _userPosition!.latitude,
        _userPosition!.longitude,
        pro.gpsLat,
        pro.gpsLng,
      );
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      primaryColor.withOpacity(0.15),
                  backgroundImage: pro.photoUrl.isNotEmpty
                      ? NetworkImage(pro.photoUrl)
                      : null,
                  child: pro.photoUrl.isEmpty
                      ? Text(
                          pro.nom.isNotEmpty
                              ? pro.nom[0].toUpperCase()
                              : '?',
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        pro.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      if (pro.categorie.isNotEmpty)
                        Container(
                          margin:
                              const EdgeInsets.only(top: 4),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                primaryColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          child: Text(
                            pro.categorie,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (distance != null)
                  Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),

            if (pro.bio.isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(
                pro.bio,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            if (pro.ville.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pro.ville,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'Carte des prestataires',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _initMap,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                  ),
                  SizedBox(height: 16),
                  Text('Chargement de la carte...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ElevatedButton.icon(
                          onPressed: _initMap,
                          icon:
                              const Icon(Icons.refresh),
                          label:
                              const Text('Réessayer'),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                primaryColor,
                            foregroundColor:
                                Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _userPosition ??
                                _defaultPosition,
                        initialZoom: 13,
                        minZoom: 5,
                        maxZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.mitan.app',
                        ),

                        MarkerLayer(
                          markers: _buildMarkers(),
                        ),
                      ],
                    ),

                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.1),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 16,
                            ),

                            const SizedBox(width: 6),

                            const Text(
                              'Moi',
                              style:
                                  TextStyle(fontSize: 12),
                            ),

                            const SizedBox(width: 12),

                            const Icon(
                              Icons.location_on,
                              color: primaryColor,
                              size: 16,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              '${_pros.length} prestataire${_pros.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}