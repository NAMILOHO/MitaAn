import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnlineIndicator extends StatelessWidget {
  final String userId;
  final double size;

  const OnlineIndicator({
    super.key,
    required this.userId,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final isOnline = data?['isOnline'] as bool? ?? false;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFF4CAF50) : Colors.grey.shade400,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        );
      },
    );
  }
}
