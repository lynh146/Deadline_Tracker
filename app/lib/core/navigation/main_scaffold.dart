import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'bottom_nav.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/stats/stats_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../repositories/task_repository.dart';
import '../../services/task_service.dart';
import '../../screens/task/task_create_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  late final TaskService _taskService;
  late final String _userId;

  // dùng để rebuild tab khi tạo task xong
  int _refreshSeed = 0;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _userId = '';
    } else {
      _userId = user.uid;
    }

    _taskService = TaskService(TaskRepository());
  }

  List<Widget> get _pages => [
    HomeScreen(key: ValueKey('home_$_refreshSeed')),
    CalendarScreen(key: ValueKey('cal_$_refreshSeed')),
    const SizedBox(), // placeholder cho nút +
    StatsScreen(
      key: ValueKey('stats_$_refreshSeed'),
      taskService: _taskService,
      userId: _userId,
    ),
    const ProfileScreen(),
  ];

  void _onTabChanged(int index) async {
    if (index == 2) {
      // mở màn Tạo công việc
      final created = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TaskCreateScreen()),
      );

      // create screen của bạn pop(true) khi tạo thành công
      if (created == true) {
        setState(() {
          _refreshSeed++; // rebuild Home/Calendar/Stats để reload UI
          _currentIndex = 0; // quay về Home
        });
      }
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D0FF),
      body: Stack(
        children: [
          Positioned.fill(child: _pages[_currentIndex]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNav(currentIndex: _currentIndex, onTap: _onTabChanged),
          ),
        ],
      ),
    );
  }
}
