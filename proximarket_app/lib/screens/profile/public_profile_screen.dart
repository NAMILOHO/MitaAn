import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final UserService _userService = UserService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _userService.getUserProfile(widget.userId);
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Public'),
        backgroundColor: const Color(0xFF1D9E75),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Utilisateur non trouvé'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: _user!.photoUrl.isNotEmpty
                            ? NetworkImage(_user!.photoUrl)
                            : null,
                        child: _user!.photoUrl.isEmpty
                            ? Text(
                                _user!.nom.isNotEmpty
                                    ? _user!.nom[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 40),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _user!.nom,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      if (_user!.isPro) ...[
                        const SizedBox(height: 8),
                        Text(
                          _user!.categorie,
                          style: const TextStyle(
                              fontSize: 16, color: Color(0xFF1D9E75)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(_user!.bio),
                      // Tu pourras ajouter plus tard la liste de ses annonces
                    ],
                  ),
                ),
    );
  }
}