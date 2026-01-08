import 'package:flutter/material.dart';
import '../../services/task_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    _testDb();
  }

  Future<void> _testDb() async {
    final tasks = await TaskService.getAllTasks();
    print('TASKS IN DB: ${tasks.length}');
    for (final t in tasks) {
      print('• ${t.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Home Tab')));
  }
}
