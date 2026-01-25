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
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('visibleAt', isLessThanOrEqualTo: Timestamp.now())
        .snapshots()
        .map((snap) {
          int unread = 0;
          for (final d in snap.docs) {
            final data = d.data();
            if (data['isRead'] != true) unread++;
          }
          return unread;
        });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _watchUnreadCount(),
      builder: (context, snap) {
        final count = snap.hasError ? 0 : (snap.data ?? 0);

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
