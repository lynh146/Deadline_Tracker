import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  Color _iconColor(int index) =>
      currentIndex == index ? AppColors.primary : AppColors.textGrey;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          //4 icons bên trái và phải
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(Icons.home_rounded, 0),
                _item(Icons.calendar_month_rounded, 1),
                const SizedBox(width: 64),
                _item(Icons.insert_chart_outlined_rounded, 3),
                _item(Icons.person_outline_rounded, 4),
              ],
            ),
          ),

          // nút +
          Positioned(
            top: -28,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, int index) {
    return IconButton(
      onPressed: () => onTap(index),
      icon: Icon(icon, size: 28, color: _iconColor(index)),
    );
  }
}
