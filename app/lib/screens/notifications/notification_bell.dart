import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationBell extends StatelessWidget {
  final String userId;
  final VoidCallback onTap;

  const NotificationBell({
    super.key,
    required this.userId,
    required this.onTap,
  });

  Stream<int> _watchUnreadCount() {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications');

    //ấy tất cả notifications realtime rồi tự đếm unread ở client
    return col.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final now = Timestamp.now();

      int count = 0;
      for (final d in snap.docs) {
        final data = d.data();

        final Timestamp? visibleAt = data['visibleAt'] is Timestamp
            ? data['visibleAt'] as Timestamp
            : null;

        final bool isVisible =
            visibleAt == null || visibleAt.compareTo(now) <= 0;

        final bool isRead = data['isRead'] == true;

        if (isVisible && !isRead) count++;
      }

      return count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _watchUnreadCount(),
      builder: (context, snap) {
        final count = snap.data ?? 0;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.notifications_none, color: Colors.black),
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
