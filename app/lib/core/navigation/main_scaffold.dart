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
import '../../core/theme/app_colors.dart';

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

  // ✅ mỗi tab 1 navigator stack riêng
  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? '';

    _taskService = TaskService(TaskRepository());
  }

  Future<void> _openCreate() async {
    // ✅ đẩy create lên “root” để che toàn bộ (bottom vẫn nằm dưới route root)
    final created = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TaskCreateScreen()));

    if (created == true) {
      setState(() {
        _refreshSeed++;
        _currentIndex = 0; // quay về Home
        // reset stack của tab hiện tại (tuỳ bạn, có thể bỏ)
        for (final k in _navKeys) {
          k.currentState?.popUntil((r) => r.isFirst);
        }
      });
    }
  }

  void _onTabChanged(int index) async {
    if (index == 2) {
      await _openCreate();
      return;
    }

    // nếu bấm lại đúng tab hiện tại -> pop về root của tab đó
    final realIndex = _mapIndex(index);
    final currentReal = _mapIndex(_currentIndex);

    if (realIndex == currentReal) {
      _navKeys[realIndex].currentState?.popUntil((r) => r.isFirst);
      return;
    }

    setState(() => _currentIndex = index);
  }

  // vì có nút + ở giữa, ta map index về 4 tab thật (0..3)
  int _mapIndex(int bottomIndex) {
    // bottomIndex: 0 Home, 1 Calendar, 2 +, 3 Stats, 4 Profile
    if (bottomIndex <= 1) return bottomIndex; // 0,1
    if (bottomIndex >= 3) return bottomIndex - 1; // 3->2, 4->3
    return 0; // không dùng cho index=2
  }

  Widget _buildTabNavigator({
    required int tabIndex, // 0..3 (Home/Calendar/Stats/Profile)
    required Widget root,
  }) {
    return Navigator(
      key: _navKeys[tabIndex],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _mapIndex(_currentIndex);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: tabIndex,
              children: [
                _buildTabNavigator(
                  tabIndex: 0,
                  root: HomeScreen(key: ValueKey('home_$_refreshSeed')),
                ),
                _buildTabNavigator(
                  tabIndex: 1,
                  root: CalendarScreen(key: ValueKey('cal_$_refreshSeed')),
                ),
                _buildTabNavigator(
                  tabIndex: 2,
                  root: StatsScreen(
                    key: ValueKey('stats_$_refreshSeed'),
                    taskService: _taskService,
                    userId: _userId,
                  ),
                ),
                _buildTabNavigator(tabIndex: 3, root: const ProfileScreen()),
              ],
            ),
          ),

          // ✅ bottom luôn nằm “trên cùng”
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
