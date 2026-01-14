import '../models/deadline_task.dart';
import '../repositories/task_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'notification_service.dart';

// Service = LOGIC NGHIỆP VỤ
//
// - Mỗi màn hình gọi Service
// - Service gọi Repository
// - UI KHÔNG ĐƯỢC query Firebase
class TaskService {
  TaskService(this._repo);

  final TaskRepository _repo;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

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

  // Lấy danh sách task theo TRẠNG THÁI
  // Dùng cho 4 ô: completed / inProgress / upcoming / overdue
  Future<List<Task>> getTasksByStatus(String userId, TaskStatus status) async {
    final all = await _repo.getTasksByUser(userId);

    return all.where((t) => t.status == status).toList();
  }

  // Lấy N task trễ hạn MỚI NHẤT
  // Mặc định lấy 2 task
  Future<List<Task>> getOverdueLatest(String userId, {int limit = 2}) async {
    final all = await _repo.getTasksByUser(userId);

    final overdue = all.where((t) => t.isOverdue).toList()
      ..sort((a, b) => b.dueAt.compareTo(a.dueAt));

    return overdue.take(limit).toList();
  }

  // Danh sách task đang làm
  // Sort:
  // - Ưu tiên ngày gần hơn
  // - Cùng ngày → progress ít hơn trước
  Future<List<Task>> getInProgressSorted(String userId) async {
    final all = await _repo.getTasksByUser(userId);

    final inProgress = all.where((t) => t.isInProgress).toList();

    inProgress.sort((a, b) {
      final dateCompare = a.dueAt.compareTo(b.dueAt);
      if (dateCompare != 0) return dateCompare;
      return a.progress.compareTo(b.progress);
    });

    return inProgress;
  }

  // CREATE TASK
  Future<void> createTask({required String userId, required Task task}) async {
    // VALIDATE NGHIỆP VỤ
    if (task.dueAt.isBefore(task.startAt)) {
      throw Exception('End date must be after start date');
    }

    await _repo.addTask(userId: userId, task: task);
    // NOTIFICATION – deadline
    await NotificationService.instance.schedule(
      id: task.hashCode,
      title: 'Deadline tới hạn',
      body: task.title,
      time: task.dueAt,
    );

    //  NOTIFICATION – reminder
    for (final remindTime in task.remindAt) {
      await NotificationService.instance.schedule(
        id: remindTime.hashCode,
        title: 'Nhắc việc',
        body: task.title,
        time: remindTime,
      );
    }
    // ANALYTICS
    await _analytics.logEvent(
      name: 'create_task',
      parameters: {'has_reminder': task.remindAt.isNotEmpty},
    );
  }

  //UPDATE TASK
  Future<void> updateTask({required String docId, required Task task}) async {
    // Validate ngày
    if (task.dueAt.isBefore(task.startAt)) {
      throw Exception('End date must be after start date');
    }

    await _repo.updateTask(docId: docId, task: task);
    // CANCEL notification cũ
    await NotificationService.instance.cancel(task.hashCode);

    // RESCHEDULE deadline mới
    await NotificationService.instance.schedule(
      id: task.hashCode,
      title: 'Deadline cập nhật',
      body: task.title,
      time: task.dueAt,
    );

    // RESCHEDULE reminder
    for (final remindTime in task.remindAt) {
      await NotificationService.instance.schedule(
        id: remindTime.hashCode,
        title: 'Nhắc việc',
        body: task.title,
        time: remindTime,
      );
    }

    //ANALYTICS: khi task hoàn thành
    if (task.progress == 100) {
      await _analytics.logEvent(
        name: 'complete_task',
        parameters: {'due_date': task.dueAt.toIso8601String()},
      );
    }
  }

  // DELETE TASK
  Future<void> deleteTask(String docId, Task task) async {
    await _repo.deleteTask(docId);
    // CANCEL notification
    await NotificationService.instance.cancel(task.hashCode);

    //ANALYTICS
    await _analytics.logEvent(name: 'delete_task');
  }
}
