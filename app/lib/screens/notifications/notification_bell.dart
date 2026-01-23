import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.userId,
    required this.onTap,
    this.iconColor = Colors.black,
  });

  final String userId;
  final VoidCallback onTap;
  final Color iconColor;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('notifications');

  Stream<int> _unreadCount() {
    return _col
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _unreadCount(),
      builder: (context, snap) {
        final unread = snap.data ?? 0;

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none, size: 26, color: iconColor),

                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          unread > 99 ? '99+' : unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
