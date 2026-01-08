import 'package:flutter/material.dart';
import '../calendar/calendar_screen.dart';
import '../task/add_task_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/task_service.dart';
import '../../core/theme/app_colors.dart';
import 'home_tab.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _index;

  final List<Widget> _tabs = const [
    HomeTab(),
    CalendarScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _onFabTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddTaskScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],

      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _onFabTap,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        child: BottomAppBar(
          color: Colors.white,
          elevation: 8,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home,
                    label: 'Home',
                    active: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  _NavItem(
                    icon: Icons.calendar_month,
                    label: 'Calendar',
                    active: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                  const SizedBox(width: 40),
                  _NavItem(
                    icon: Icons.bar_chart,
                    label: 'Stats',
                    active: _index == 2,
                    onTap: () => setState(() => _index = 2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    active: _index == 3,
                    onTap: () => setState(() => _index = 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// test
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
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
