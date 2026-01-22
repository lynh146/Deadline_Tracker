import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/deadline_task.dart';
import '../../services/task_service.dart';
import '../../widgets/task_item_card.dart';
import '../task/task_detail_screen.dart';

class StatusListScreen extends StatefulWidget {
  final String title;
  final TaskStatus status; // Enum trạng thái để lọc
  final TaskService taskService;
  final String userId;

  const StatusListScreen({
    Key? key,
    required this.title,
    required this.status,
    required this.taskService,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatusListScreen> createState() => _StatusListScreenState();
}

class _StatusListScreenState extends State<StatusListScreen> {
  int _tabIndex = 0; // 0: Tuần này, 1: Tháng này, 2: Tất cả

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Tím nhạt
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          // --- PHẦN BẠN CẦN: THANH TAB FILTER ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25), // Bo tròn như viên thuốc
            ),
            child: Row(
              children: [
                _buildTabItem("Tuần này", 0),
                _buildTabItem("Tháng này", 1),
                _buildTabItem("Tất cả", 2),
              ],
            ),
          ),
          // --------------------------------------

          // DANH SÁCH TASK
          Expanded(
            child: FutureBuilder<List<Task>>(
              // Gọi service lấy toàn bộ task theo status trước
              future: widget.taskService.getTasksByStatus(
                widget.userId,
                widget.status,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text("Không có task '${widget.title}' nào."),
                  );
                }

                // LOGIC LỌC LOCAL (Client-side filter)
                List<Task> allTasks = snapshot.data!;
                List<Task> filteredTasks = _filterTasksByTime(allTasks);

                if (filteredTasks.isEmpty) {
                  return const Center(
                    child: Text("Không có task trong khoảng thời gian này."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (ctx, i) => TaskItemCard(
                    task: filteredTasks[i],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(
                            task: filteredTasks[i],
                            docId: filteredTasks[i].id.toString(),
                            taskService: widget.taskService,
                            userId: widget.userId,
                          ),
                        ),
                      ).then((_) => setState(() {})); // Refresh khi quay lại
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget từng nút Tab
  Widget _buildTabItem(String text, int index) {
    bool isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.surface
                : Colors.transparent, // Tab chọn có màu nền khác
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  // Hàm lọc danh sách theo thời gian
  List<Task> _filterTasksByTime(List<Task> tasks) {
    final now = DateTime.now();
    if (_tabIndex == 2) return tasks; // Tất cả

    return tasks.where((t) {
      if (_tabIndex == 0) {
        // Tuần này (Logic đơn giản: cùng năm và cùng số tuần, hoặc khoảng cách ngày < 7)
        // Để chính xác: check xem task.dueAt có nằm trong Thứ 2 -> CN tuần này không
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return t.dueAt.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            t.dueAt.isBefore(endOfWeek);
      } else {
        // Tháng này
        return t.dueAt.year == now.year && t.dueAt.month == now.month;
      }
    }).toList();
  }
}
