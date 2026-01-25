import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deadline_task.dart';

class TaskRepository {
  final _db = FirebaseFirestore.instance;

  // Lấy TẤT CẢ task của 1 user
  Future<List<Task>> getTasksByUser(String userId) async {
    final snapshot = await _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map(_fromDoc).toList();
  }

  Stream<List<Task>> watchTasksByUser(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  //Lấy 1 task theo docId (để so sánh trước/sau khi update)
  Future<Task?> getTaskById({required String docId}) async {
    final doc = await _db.collection('tasks').doc(docId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
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

  // Map Firestore Document → Task
  Task _fromDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Task(
      id: doc.id,
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

  // CREATE
  Future<String> addTask({required String userId, required Task task}) async {
    final ref = await _db.collection('tasks').add({
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

    return ref.id;
  }

  // UPDATE
  Future<void> updateTask({required String docId, required Task task}) async {
    await _db.collection('tasks').doc(docId).update({
      'title': task.title,
      'description': task.description,
      'startAt': Timestamp.fromDate(task.startAt),
      'dueAt': Timestamp.fromDate(task.dueAt),
      'remindAt': task.remindAt.map((e) => Timestamp.fromDate(e)).toList(),
      'progress': task.progress,
      'updatedAt': Timestamp.now(),
    });
  }

  // DELETE
  Future<void> deleteTask(String docId) async {
    await _db.collection('tasks').doc(docId).delete();
  }
}
