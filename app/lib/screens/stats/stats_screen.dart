import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/deadline_task.dart';
import '../../repositories/task_repository.dart';
import 'status_list_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _repo = TaskRepository();

  bool _loading = true;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        _tasks = [];
        _loading = false;
      });
      return;
    }

    final tasks = await _repo.getTasksByUser(user.uid);

    setState(() {
      _tasks = tasks;
      _loading = false;
    });
  }

  // ===== STATUS LOGIC (DAY 5) =====
  List<Task> get completed => _tasks.where((t) => t.progress >= 100).toList();

  List<Task> get inProgress =>
      _tasks.where((t) => t.progress > 0 && t.progress < 100).toList();

  List<Task> get overdue => _tasks
      .where((t) => t.progress < 100 && t.dueAt.isBefore(DateTime.now()))
      .toList();

  List<Task> get upcoming => _tasks
      .where((t) => t.progress == 0 && t.dueAt.isAfter(DateTime.now()))
      .toList();

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (FirebaseAuth.instance.currentUser == null) {
      return const Scaffold(body: Center(child: Text('Bạn chưa đăng nhập')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE1D0FF),
      appBar: AppBar(
        title: const Text('Thống kê'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusGrid(context),
          const SizedBox(height: 24),
          _overdueSection(context),
          const SizedBox(height: 24),
          _progressSection(),
        ],
      ),
    );
  }

  // ===== UI =====

  Widget _statusGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _statusCard('Hoàn thành', completed),
        _statusCard('Đang làm', inProgress),
        _statusCard('Sắp tới', upcoming),
        _statusCard('Hết hạn', overdue),
      ],
    );
  }

  Widget _statusCard(String title, List<Task> tasks) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StatusListScreen(title: title, tasks: tasks),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${tasks.length}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _overdueSection(BuildContext context) {
    final latest = overdue.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hết hạn',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...latest.map(_taskTile),
        if (overdue.length > 2)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      StatusListScreen(title: 'Hết hạn', tasks: overdue),
                ),
              );
            },
            child: const Text('Xem tất cả'),
          ),
      ],
    );
  }

  Widget _progressSection() {
    final list = [...inProgress];

    // SORT: ngày ↑, cùng ngày progress ↑
    list.sort((a, b) {
      final d = a.dueAt.compareTo(b.dueAt);
      if (d != 0) return d;
      return a.progress.compareTo(b.progress);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiến độ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...list.map(_taskTile),
      ],
    );
  }

  Widget _taskTile(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: task.progress / 100),
        ],
      ),
    );
  }
}
