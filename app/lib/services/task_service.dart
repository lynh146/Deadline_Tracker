import '../models/task.dart';
import '../models/reminder.dart';
import '../core/database/app_database.dart';
import 'notification_service.dart';

class TaskService {
  // STATUS LOGIC
  static int _calcStatus(DateTime dueAt) {
    final now = DateTime.now();

    if (dueAt.isBefore(now)) return 2; // overdue
    if (dueAt.difference(now).inHours <= 48) return 1; // due soon
    return 0; // upcoming
  }

  // ADD TASK + REMINDERS (TRANSACTION)
  static Future<int> addTask(Task task) async {
    final db = await AppDatabase.database;

    return await db.transaction((txn) async {
      // insert task
      final taskId = await txn.insert('tasks', {
        'title': task.title,
        'description': task.description,
        'startAt': task.startAt.millisecondsSinceEpoch,
        'dueAt': task.dueAt.millisecondsSinceEpoch,
        'priority': task.priority,
        'progress': task.progress,
        'status': _calcStatus(task.dueAt),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      // insert reminders
      for (final r in task.remindAt) {
        await txn.insert('reminders', {
          'taskId': taskId,
          'remindAt': r.millisecondsSinceEpoch,
        });
      }

      return taskId;
    });
  }

  // GET ALL TASKS
  static Future<List<Task>> getAllTasks() async {
    final db = await AppDatabase.database;
    final maps = await db.query('tasks');

    return maps.map((e) {
      return Task(
        id: e['id'] as int,
        title: e['title'] as String,
        description: e['description'] as String,
        startAt: DateTime.fromMillisecondsSinceEpoch(e['startAt'] as int),
        dueAt: DateTime.fromMillisecondsSinceEpoch(e['dueAt'] as int),
        remindAt: [], // reminder load riêng
        priority: e['priority'] as int,
        progress: e['progress'] as int,
        status: e['status'] as int,
      );
    }).toList();
  }

  // GET REMINDERS BY TASK
  static Future<List<Reminder>> getRemindersByTask(int taskId) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'reminders',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );

    return maps.map((e) {
      return Reminder(
        id: e['id'] as int,
        taskId: e['taskId'] as int,
        remindAt: DateTime.fromMillisecondsSinceEpoch(e['remindAt'] as int),
      );
    }).toList();
  }

  // DELETE TASK + CANCEL ALL REMINDERS
  static Future<void> deleteTask(int taskId) async {
    final db = await AppDatabase.database;

    final reminders = await getRemindersByTask(taskId);

    for (final r in reminders) {
      await NotificationService.cancel(r.id);
    }

    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }
}
