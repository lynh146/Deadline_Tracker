import '../models/deadline_task.dart';
import '../repositories/task_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'notification_service.dart';

class TaskService {
  TaskService(this._repo);

  final TaskRepository _repo;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ===== HELPER =====
  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) => _startOfDay(d).add(const Duration(days: 1));

  DateTime _startOfWeek(DateTime today) {
    return _startOfDay(
      today,
    ).subtract(Duration(days: today.weekday - DateTime.monday));
  }

  DateTime _endOfWeek(DateTime today) =>
      _startOfWeek(today).add(const Duration(days: 7));

  bool _inRange(DateTime x, DateTime start, DateTime endExclusive) {
    return !x.isBefore(start) && x.isBefore(endExclusive);
  }

  // Notification id ổn định theo docId
  // salt:
  // 0: deadline
  // 1..n: reminders
  // 100: startAt
  // 200: overdue
  int _notifId(String docId, int salt) {
    return (docId.hashCode & 0x7fffffff) + salt;
  }

  // HOME
  //Task tới hạn HÔM NAY
  Future<List<Task>> getTodayTasks(String userId) async {
    final all = await _repo.getTasksByUser(userId);

    final now = DateTime.now();
    final startToday = _startOfDay(now);
    final endToday = _endOfDay(now);

    return all
        .where((t) => _inRange(t.dueAt, startToday, endToday) && !t.isCompleted)
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }
  // Tổng task trong TUẦN (Home – ô thống kê)

  Future<int> getWeeklyTasks(String userId) async {
    final all = await _repo.getTasksByUser(userId);

    final now = DateTime.now();
    final startWeek = _startOfWeek(now);
    final endWeek = _endOfWeek(now);

    return all
        .where((t) => !t.isCompleted && _inRange(t.dueAt, startWeek, endWeek))
        .length;
  }

  // CALENDAR
  // Task theo NGÀY (Calendar Week)

  Future<List<Task>> getTasksByDate(String userId, DateTime day) async {
    final all = await _repo.getTasksByUser(userId);
    final start = _startOfDay(day);
    final end = _endOfDay(day);

    return all.where((t) => _inRange(t.dueAt, start, end)).toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  // STATUS
  // Lấy danh sách task theo TRẠNG THÁI
  // Dùng cho 4 ô: completed / inProgress / upcoming / overdue
  Future<List<Task>> getTasksByStatus(String userId, TaskStatus status) async {
    final all = await _repo.getTasksByUser(userId);
    return all.where((t) => t.status == status).toList();
  }

  //QUÁ HẠN
  Future<List<Task>> getOverdueLatest(String userId, {int limit = 2}) async {
    final all = await _repo.getTasksByUser(userId);

    final overdue = all.where((t) => t.isOverdue).toList()
      ..sort((a, b) => b.dueAt.compareTo(a.dueAt));

    return overdue.take(limit).toList();
  }
  // ĐANG TIẾN HÀNH
  // Sắp xếp theo dueAt (càng gần càng lên trên), cùng dueAt thì progress thấp lên trên

  Future<List<Task>> getInProgressSorted(String userId) async {
    final all = await _repo.getTasksByUser(userId);

    final inProgress = all.where((t) => t.isInProgress).toList();
    inProgress.sort((a, b) {
      final c = a.dueAt.compareTo(b.dueAt);
      if (c != 0) return c;
      return a.progress.compareTo(b.progress);
    });

    return inProgress;
  }

  // CHƯA LÀM
  Future<List<Task>> getNotStartedTasks(String userId) async {
    final all = await _repo.getTasksByUser(userId);
    final now = DateTime.now();

    final list = all.where((t) {
      final notDone = !t.isCompleted;
      final notOverdue = t.dueAt.isAfter(now);
      return notDone && notOverdue && t.progress == 0;
    }).toList();

    list.sort((a, b) {
      final c = a.dueAt.compareTo(b.dueAt);
      if (c != 0) return c;
      return a.progress.compareTo(b.progress);
    });

    return list;
  }

  //SẮP HẾT HẠN = ĐÚNG NGÀY (1/3/5)
  Future<List<Task>> getDueSoonTasks(String userId, {required int days}) async {
    final all = await _repo.getTasksByUser(userId);

    if (days != 1 && days != 3 && days != 5) {
      throw Exception('days must be 1, 3, or 5');
    }

    final now = DateTime.now();
    final targetDay = _startOfDay(now).add(Duration(days: days));
    final start = targetDay;
    final end = _endOfDay(targetDay);

    final list = all.where((t) {
      if (t.isCompleted) return false;
      if (t.isOverdue) return false;
      return _inRange(t.dueAt, start, end);
    }).toList();

    list.sort((a, b) {
      final c = a.dueAt.compareTo(b.dueAt);
      if (c != 0) return c;
      return a.progress.compareTo(b.progress);
    });

    return list;
  }

  Future<List<Task>> getDueSoonLatest(String userId, {int limit = 2}) async {
    final one = await getDueSoonTasks(userId, days: 1);
    final three = await getDueSoonTasks(userId, days: 3);
    final five = await getDueSoonTasks(userId, days: 5);

    final merged = <Task>[...one, ...three, ...five];

    final seen = <String>{};
    final distinct = <Task>[];
    for (final t in merged) {
      final key = t.id ?? '${t.title}-${t.dueAt.toIso8601String()}';
      if (seen.add(key)) distinct.add(t);
    }

    distinct.sort((a, b) {
      final c = a.dueAt.compareTo(b.dueAt);
      if (c != 0) return c;
      return a.progress.compareTo(b.progress);
    });

    return distinct.take(limit).toList();
  }

  // NOTIFICATION HELPERS FOR TASKS
  Future<void> _scheduleStart({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    // Nhắc vào đúng startAt
    if (task.startAt.isAfter(DateTime.now())) {
      final title = 'Bắt đầu công việc';
      final body = 'Hôm nay bắt đầu: ${task.title}';

      await NotificationService.instance.schedule(
        id: _notifId(docId, 100),
        title: title,
        body: body,
        time: task.startAt,
        channelId: NotificationService.chStart,
        channelName: 'Start',
        channelDesc: 'Start task reminders',
      );

      await NotificationService.instance.saveToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: 'start',
        createdAt: DateTime.now(),
        scheduledFor: task.startAt,
        taskDocId: docId,
      );
    }
  }

  Future<void> _scheduleDeadline({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    final title = 'Deadline tới hạn';
    final body = task.title;

    await NotificationService.instance.schedule(
      id: _notifId(docId, 0),
      title: title,
      body: body,
      time: task.dueAt,
      channelId: NotificationService.chDeadline,
      channelName: 'Deadline',
      channelDesc: 'Deadline notifications',
    );

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: title,
      body: body,
      type: 'deadline',
      createdAt: DateTime.now(),
      scheduledFor: task.dueAt,
      taskDocId: docId,
    );

    // Overdue notification (1 minute after dueAt)
    final overdueTime = task.dueAt.add(const Duration(minutes: 1));
    final oTitle = 'Công việc đã hết hạn';
    final oBody = task.title;

    await NotificationService.instance.schedule(
      id: _notifId(docId, 200),
      title: oTitle,
      body: oBody,
      time: overdueTime,
      channelId: NotificationService.chOverdue,
      channelName: 'Overdue',
      channelDesc: 'Overdue notifications',
    );

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: oTitle,
      body: oBody,
      type: 'overdue',
      createdAt: DateTime.now(),
      scheduledFor: overdueTime,
      taskDocId: docId,
    );
  }

  Future<void> _scheduleReminders({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    for (int i = 0; i < task.remindAt.length; i++) {
      final t = task.remindAt[i];

      // nhắc phải nằm trước dueAt và sau hiện tại
      if (t.isBefore(DateTime.now())) continue;
      if (!t.isBefore(task.dueAt)) continue;

      final title = 'Nhắc việc';
      final body = task.title;

      await NotificationService.instance.schedule(
        id: _notifId(docId, i + 1),
        title: title,
        body: body,
        time: t,
        channelId: NotificationService.chReminder,
        channelName: 'Reminder',
        channelDesc: 'Reminder notifications',
      );

      await NotificationService.instance.saveToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: 'reminder',
        createdAt: DateTime.now(),
        scheduledFor: t,
        taskDocId: docId,
      );
    }
  }

  Future<void> _cancelAllTaskNotifs(String docId) async {
    // tối đa 3 reminders
    for (int i = 0; i <= 3; i++) {
      await NotificationService.instance.cancel(_notifId(docId, i));
    }
    await NotificationService.instance.cancel(_notifId(docId, 100));
    await NotificationService.instance.cancel(_notifId(docId, 200));
  }

  // CREATE
  Future<void> createTask({required String userId, required Task task}) async {
    if (task.dueAt.isBefore(task.startAt)) {
      throw Exception('End date must be after start date');
    }

    final docId = await _repo.addTask(userId: userId, task: task);

    // Thông báo “tạo công việc”
    await NotificationService.instance.showNow(
      id: _notifId(docId, 999),
      title: 'Đã tạo công việc',
      body: task.title,
      channelId: NotificationService.chGeneral,
      channelName: 'General',
      channelDesc: 'General notifications',
    );
    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: 'Đã tạo công việc',
      body: task.title,
      type: 'create',
      createdAt: DateTime.now(),
      taskDocId: docId,
    );

    // Schedule start/reminder/deadline/overdue
    await _scheduleStart(userId: userId, docId: docId, task: task);
    await _scheduleReminders(userId: userId, docId: docId, task: task);
    await _scheduleDeadline(userId: userId, docId: docId, task: task);

    await _analytics.logEvent(
      name: 'create_task',
      parameters: {'has_reminder': task.remindAt.isNotEmpty ? 1 : 0},
    );
  }

  // UPDATE
  Future<void> updateTask({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    if (task.dueAt.isBefore(task.startAt)) {
      throw Exception('End date must be after start date');
    }

    await _repo.updateTask(docId: docId, task: task);

    // thông báo “cập nhật tiến độ” (mỗi lần update)
    final pTitle = 'Đã cập nhật tiến độ';
    final pBody = '${task.title}: ${task.progress}%';

    await NotificationService.instance.showNow(
      id: _notifId(docId, 888),
      title: pTitle,
      body: pBody,
      channelId: NotificationService.chProgress,
      channelName: 'Progress',
      channelDesc: 'Progress updates',
    );

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: pTitle,
      body: pBody,
      type: 'progress',
      createdAt: DateTime.now(),
      taskDocId: docId,
    );

    // cancel + reschedule lịch
    await _cancelAllTaskNotifs(docId);
    await _scheduleStart(userId: userId, docId: docId, task: task);
    await _scheduleReminders(userId: userId, docId: docId, task: task);
    await _scheduleDeadline(userId: userId, docId: docId, task: task);

    if (task.progress == 100) {
      await _analytics.logEvent(
        name: 'complete_task',
        parameters: {'due_date': task.dueAt.toIso8601String()},
      );
    }
  }

  //DELETE
  Future<void> deleteTask({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    await _repo.deleteTask(docId);
    await _cancelAllTaskNotifs(docId);

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: 'Đã xoá công việc',
      body: task.title,
      type: 'delete',
      createdAt: DateTime.now(),
      taskDocId: docId,
    );

    await _analytics.logEvent(name: 'delete_task');
  }
}
