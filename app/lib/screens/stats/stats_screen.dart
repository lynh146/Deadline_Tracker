import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/deadline_task.dart';
import '../../services/task_service.dart';
import '../../widgets/task_item_card.dart';
import 'status_list_screen.dart';
import '../task/task_detail_screen.dart';

class StatsScreen extends StatefulWidget {
  final TaskService taskService;
  final String userId;

  const StatsScreen({Key? key, required this.taskService, required this.userId})
    : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Màu tím nền #E1D0FF
      appBar: AppBar(
        title: const Text(
          "Trạng thái",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. GRID 4 Ô TRẠNG THÁI (Đúng mẫu ảnh) ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.6, // Tỉ lệ chữ nhật dẹt như ảnh
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatBox(
                  "Đã hoàn thành",
                  TaskStatus.completed,
                  AppColors.success,
                  Icons.check_circle,
                ),
                _buildStatBox(
                  "Đang làm",
                  TaskStatus.inProgress,
                  Colors.amber,
                  Icons.hourglass_top,
                ),
                _buildStatBox(
                  "Sắp tới hạn",
                  TaskStatus.upcoming,
                  Colors.yellow,
                  Icons.warning_amber_rounded,
                ),
                _buildStatBox(
                  "Hết hạn",
                  TaskStatus.overdue,
                  AppColors.danger,
                  Icons.cancel,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 2. KHUNG "CẦN CHÚ Ý" (Màu tím nhạt) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.detailCard, // Màu #EDE3FF
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Cần chú ý",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // Chuyển sang xem tất cả task overdue
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StatusListScreen(
                                title: "Cần chú ý",
                                status: TaskStatus.overdue,
                                taskService: widget.taskService,
                                userId: widget.userId,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Xem tất cả",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // List 2 task overdue demo (Hoặc load từ API)
                  FutureBuilder<List<Task>>(
                    future: widget.taskService.getOverdueLatest(
                      widget.userId,
                      limit: 2,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Không có task cần chú ý.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!
                            .map(
                              (t) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Đến hạn ${t.dueAt.day}/${t.dueAt.month}",
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Logic hiển thị "Còn X giờ" hoặc "Trễ hạn"
                                    Text(
                                      t.isOverdue ? "Trễ hạn" : "Sắp đến",
                                      style: TextStyle(
                                        color: t.isOverdue
                                            ? AppColors.danger
                                            : AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. TIẾN ĐỘ CÔNG VIỆC (List bên dưới) ---
            const Text(
              "Tiến độ công việc",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            FutureBuilder<List<Task>>(
              future: widget.taskService.getInProgressSorted(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return const Text("Chưa có công việc nào.");

                return Column(
                  children: snapshot.data!
                      .map(
                        (task) => TaskItemCard(
                          task: task,
                          onTap: () {
                            // Bấm vào item thì sang trang Detail
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(
                                  task: task,
                                  docId: task.id
                                      .toString(), // Service dùng String ID
                                  taskService: widget.taskService,
                                  userId: widget.userId,
                                ),
                              ),
                            ).then(
                              (_) => setState(() {}),
                            ); // Refresh lại khi quay về
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget 4 ô vuông
  Widget _buildStatBox(
    String title,
    TaskStatus status,
    Color iconColor,
    IconData icon,
  ) {
    return FutureBuilder<List<Task>>(
      future: widget.taskService.getTasksByStatus(widget.userId, status),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? "${snapshot.data!.length}" : "0";
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StatusListScreen(
                  title: title,
                  status: status,
                  taskService: widget.taskService,
                  userId: widget.userId,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
