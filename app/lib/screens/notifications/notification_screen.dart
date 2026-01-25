import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:app/models/deadline_task.dart';
import 'package:app/repositories/task_repository.dart';
import 'package:app/services/task_service.dart';
import 'package:app/screens/task/task_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key, required this.userId});

  final String userId;

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('users')
      .doc(userId)
      .collection('notifications');

  Future<void> _markAllRead(BuildContext context) async {
    try {
      final now = Timestamp.now();

      final qSnap = await _col
          .where('visibleAt', isLessThanOrEqualTo: now)
          .orderBy('visibleAt', descending: true)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int updated = 0;

      for (final d in qSnap.docs) {
        final data = d.data();

        final bool isRead = data['isRead'] == true;
        if (!isRead) {
          batch.update(d.reference, {'isRead': true});
          updated++;
        }
      }

      if (updated == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có thông báo chưa đọc.')),
        );
        return;
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã đọc hết ($updated) thông báo.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi Đọc hết: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(context),
            child: const Text(
              'Đọc hết',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col
            .where('visibleAt', isLessThanOrEqualTo: now)
            .orderBy('visibleAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa có thông báo nào.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data();

              final bool read = data['isRead'] == true;
              final String title = (data['title'] ?? 'Thông báo').toString();
              final String? body = data['body']?.toString();
              final String? taskDocId = data['taskDocId'];

              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: read ? Colors.grey : const Color(0xFF6A1B9A),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: read ? FontWeight.w600 : FontWeight.w900,
                  ),
                ),
                subtitle: body == null ? null : Text(body),
                trailing: read
                    ? null
                    : const Icon(Icons.circle, size: 8, color: Colors.red),

                onTap: () async {
                  // mark read
                  await d.reference.set({
                    'isRead': true,
                  }, SetOptions(merge: true));

                  if (taskDocId == null) return;

                  final repo = TaskRepository();
                  final tasks = await repo.getTasksByUser(userId);

                  Task? found;
                  for (final t in tasks) {
                    if (t.id == taskDocId) {
                      found = t;
                      break;
                    }
                  }
                  if (found == null) return;
                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(
                        task: found!,
                        docId: taskDocId,
                        userId: userId,
                        taskService: TaskService(repo),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
