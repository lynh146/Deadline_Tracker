import '../models/deadline_task.dart';
import '../repositories/task_repository.dart';

// Service = LOGIC NGHIỆP VỤ
//
// - Mỗi màn hình gọi Service
// - Service gọi Repository
// - UI KHÔNG ĐƯỢC query Firebase
class TaskService {
  TaskService(this._repo);

  final TaskRepository _repo;

  // HOME

  //Task tới hạn HÔM NAY
  Future<List<Task>> getTodayTasks(String userId) async {
    final all = await _repo.getTasksByUser(userId);

    final now = DateTime.now();
    final startDay = DateTime(now.year, now.month, now.day);
    final endDay = startDay.add(const Duration(days: 1));

    return all
        .where(
          (t) =>
              t.dueAt.isAfter(startDay) &&
              t.dueAt.isBefore(endDay) &&
              !t.isCompleted,
        )
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  // Tổng task trong TUẦN (Home – ô thống kê)
  Future<int> getWeeklyTasks(String userId) async {
    final all = await _repo.getTasksByUser(userId);

    final now = DateTime.now();
    final endWeek = now.add(const Duration(days: 7));

    return all.where((t) {
      return t.dueAt.isAfter(now) &&
          t.dueAt.isBefore(endWeek) &&
          !t.isCompleted;
    }).length;
  }

  //CALENDAR

  // Task theo NGÀY (Calendar Week)
  Future<List<Task>> getTasksByDate(String userId, DateTime day) async {
    final all = await _repo.getTasksByUser(userId);

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return all
        .where((t) => t.dueAt.isAfter(start) && t.dueAt.isBefore(end))
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  //STATS / STATUS

  List<Task> filterCompleted(List<Task> tasks) =>
      tasks.where((t) => t.isCompleted).toList();

  List<Task> filterOverdue(List<Task> tasks) =>
      tasks.where((t) => t.isOverdue).toList();

  List<Task> filterInProgress(List<Task> tasks) =>
      tasks.where((t) => t.isInProgress).toList();

  // CREATE TASK
  Future<void> createTask({required String userId, required Task task}) async {
    // VALIDATE NGHIỆP VỤ
    if (task.dueAt.isBefore(task.startAt)) {
      throw Exception('End date must be after start date');
    }

    await _repo.addTask(userId: userId, task: task);
  }

  //UPDATE TASK
  Future<void> updateTask({required String docId, required Task task}) async {
    // Validate ngày
    if (task.dueAt.isBefore(task.startAt)) {
      throw Exception('End date must be after start date');
    }

    await _repo.updateTask(docId: docId, task: task);
  }

  // DELETE TASK
  Future<void> deleteTask(String docId) async {
    await _repo.deleteTask(docId);
  }
}
