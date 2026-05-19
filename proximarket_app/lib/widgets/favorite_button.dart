import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ← Pour HapticFeedback
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

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

  // ✅ CORRECTION : synchroniser l'état si la liste parent change
  @override
  void didUpdateWidget(FavoriteButton old) {
    super.didUpdateWidget(old);
    if (old.favorites != widget.favorites ||
        old.serviceId != widget.serviceId) {
      setState(() {
        _isFavorite = widget.favorites.contains(widget.serviceId);
      });
    }
  }

  Future<void> _toggle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ AJOUT : retour haptique
    HapticFeedback.lightImpact();

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
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          key: ValueKey(_isFavorite),
          color: _isFavorite ? Colors.red : Colors.grey,
        ),
      ),
      tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
    );
  }
}