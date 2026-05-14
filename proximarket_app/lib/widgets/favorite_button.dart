import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';

class FavoriteButton extends StatefulWidget {
  final String serviceId;
  final List<String> favorites;

  const FavoriteButton({
    super.key,
    required this.serviceId,
    required this.favorites,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final UserService _userService = UserService();
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.favorites.contains(widget.serviceId);
  }

  Future<void> _toggle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Optimistic UI
    setState(() => _isFavorite = !_isFavorite);

    try {
      if (_isFavorite) {
        await _userService.addFavorite(uid, widget.serviceId);
      } else {
        await _userService.removeFavorite(uid, widget.serviceId);
      }
    } catch (_) {
      // Rollback si erreur
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggle,
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        color: _isFavorite ? Colors.red : Colors.grey,
      ),
      tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
    );
  }
}