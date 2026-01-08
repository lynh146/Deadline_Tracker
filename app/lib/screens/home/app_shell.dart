import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_tab.dart';
import '../calendar/calendar_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../task/add_task_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static _AppShellState of(BuildContext context) =>
      context.findAncestorStateOfType<_AppShellState>()!;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  final _navKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  void setTab(int i, {bool popToRoot = false}) {
    if (popToRoot) {
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    }
    setState(() => _index = i);
  }

  void _onTap(int i) {
    if (_index == i) {
      // bấm lại tab đang chọn -> pop về root tab đó
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => _index = i);
    }
  }

  void _onFabTap() {
    // mở AddTask trên tab hiện tại
    _navKeys[_index].currentState?.push(
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }

  Widget _tabNavigator({required int index, required Widget root}) {
    return Navigator(
      key: _navKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,

      body: IndexedStack(
        index: _index,
        children: [
          _tabNavigator(index: 0, root: const HomeTab()),
          _tabNavigator(index: 1, root: const CalendarScreen()),
          _tabNavigator(index: 2, root: const StatsScreen()),
          _tabNavigator(index: 3, root: const ProfileScreen()),
        ],
      ),

      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _onFabTap,
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 8,
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
                    onTap: () => _onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.calendar_month,
                    label: 'Calendar',
                    active: _index == 1,
                    onTap: () => _onTap(1),
                  ),
                  const SizedBox(width: 40),
                  _NavItem(
                    icon: Icons.bar_chart,
                    label: 'Stats',
                    active: _index == 2,
                    onTap: () => _onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    active: _index == 3,
                    onTap: () => _onTap(3),
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
