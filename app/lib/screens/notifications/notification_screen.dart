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

  Future<void> _markAllRead() async {
    final q = await _col.where('isRead', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Đọc hết',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('createdAt', descending: true).snapshots(),
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

                // ĐIỀU HƯỚNG KHI NHẤN VÀO THÔNG BÁO
                onTap: () async {
                  // mark read
                  await d.reference.update({'isRead': true});

                  // không có task thì thôi
                  if (taskDocId == null) return;

                  // LẤY TASK TỪ LIST
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

                  final Task task = found;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(
                        task: task,
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
