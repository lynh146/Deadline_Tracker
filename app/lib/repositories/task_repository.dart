import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deadline_task.dart';

/// Repository CHỈ LÀM 1 VIỆC:
/// - Đọc dữ liệu từ Firestore
/// - Map Firestore → Task model
///
/// KHÔNG xử lý logic hôm nay / tuần
/// KHÔNG sort theo UI
class TaskRepository {
  final _db = FirebaseFirestore.instance;

  /// Lấy TẤT CẢ task của 1 user
  Future<List<Task>> getTasksByUser(String userId) async {
    final snapshot = await _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map(_fromDoc).toList();
  }

  /// Map Firestore Document → Task
  Task _fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Task(
      id: null,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startAt: (data['startAt'] as Timestamp).toDate(),
      dueAt: (data['dueAt'] as Timestamp).toDate(),
      remindAt: (data['remindAt'] as List<dynamic>? ?? [])
          .map((e) => (e as Timestamp).toDate())
          .toList(),
      progress: data['progress'] ?? 0,
    );
  }

  /// CREATE
  Future<void> addTask({required String userId, required Task task}) async {
    await _db.collection('tasks').add({
      'userId': userId,
      'title': task.title,
      'description': task.description,
      'startAt': Timestamp.fromDate(task.startAt),
      'dueAt': Timestamp.fromDate(task.dueAt),
      'remindAt': task.remindAt.map((e) => Timestamp.fromDate(e)).toList(),
      'progress': task.progress,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }
}
