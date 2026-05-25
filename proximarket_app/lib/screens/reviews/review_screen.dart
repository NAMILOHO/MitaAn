import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';

class ReviewScreen extends StatefulWidget {
  final UserModel targetUser;

  const ReviewScreen({super.key, required this.targetUser});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _stars = 0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  static const primary = Color(0xFF1D9E75);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez une note'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('reviews').add({
      'reviewerId': myUid,
      'targetId': widget.targetUser.uid,
      'stars': _stars,
      'comment': _commentController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snap = await firestore
        .collection('reviews')
        .where('targetId', isEqualTo: widget.targetUser.uid)
        .get();
    final total = snap.docs.fold<double>(
      0,
      (totalStars, doc) =>
          totalStars + ((doc.data()['stars'] ?? 0) as num).toDouble(),
    );
    final avg = snap.docs.isEmpty ? 0.0 : total / snap.docs.length;

    await firestore.collection('users').doc(widget.targetUser.uid).update({
      'rating': avg,
      'reviewCount': snap.docs.length,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis envoyé ✅'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        widget.targetUser.nom.isNotEmpty ? widget.targetUser.nom[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Laisser un avis',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFE1F5EE),
              backgroundImage: widget.targetUser.photoUrl.isNotEmpty
                  ? NetworkImage(widget.targetUser.photoUrl)
                  : null,
              child: widget.targetUser.photoUrl.isEmpty
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 28,
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              widget.targetUser.nom,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Votre note',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => GestureDetector(
                  onTap: () => setState(() => _stars = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 40,
                      color: i < _stars
                          ? const Color(0xFFFFA726)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Partagez votre expérience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Envoyer l\'avis',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
