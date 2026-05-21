import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class FavoriteButton extends StatefulWidget {
  final String serviceId;
  final List<String> favorites;
  final Color? activeColor;
  final double size;

  const FavoriteButton({
    super.key,
    required this.serviceId,
    required this.favorites,
    this.activeColor = Colors.red,
    this.size = 20,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  late bool _isFavorite;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.favorites.contains(widget.serviceId);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.8,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    HapticFeedback.lightImpact();

    // Animation
    await _controller.reverse();
    _controller.forward();

    // Optimistic UI
    setState(() => _isFavorite = !_isFavorite);

    try {
      if (_isFavorite) {
        await _userService.addFavorite(uid, widget.serviceId);
      } else {
        await _userService.removeFavorite(uid, widget.serviceId);
      }
    } catch (_) {
      // Rollback
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(_isFavorite),
              color: _isFavorite ? widget.activeColor : const Color(0xFFB0B7C3),
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}