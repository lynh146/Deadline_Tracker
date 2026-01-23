import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Màu chủ đạo app (text title, button chính, active nav)
  static const Color primary = Color(0xFF6A0DAD);

  /// Gradient header (Splash, Auth, Home top)
  static const Color purpleStart = Color(0xFF7D26EB);
  static const Color purpleEnd = Color(0xFF6331B3);

  /// Background chung toàn app
  static const Color surface = Color(0xFFF8F8FF);

  /// Background main screens
  static const Color background = Color(0xFFE1D0FF);

  /// Card / container trắng
  static const Color white = Color(0xFFFFFFFF);

  /// Card detail (trang Detail – ảnh 4)
  static const Color detailCard = Color(0xFFEDE3FF);

  /// Nền card thống kê (ảnh 3)
  static const Color statCard = Color(0xFF3B2991);

  /// Tiến độ rất thấp / sắp trễ
  static const Color progressLow = Color(0xFFFD0E0E);

  /// Tiến độ trung bình
  static const Color progressMedium = Color(0xFFF5F90B);

  /// Tiến độ tốt
  static const Color progressHigh = Color(0xFF0EFD3A);

  /// Tiến độ hoàn thành / thành công
  static const Color success = Color(0xFF0EFD3A);

  /// Background progress
  static const Color progressBg = Color(0xFFD9D9D9);

  /// Button disabled
  static const Color disabled = Color(0xFFDADADA);

  /// Button delete (Detail)
  static const Color danger = Color(0xFFFD0E0E);

  /// Button update (Detail)
  static const Color update = Color(0xFF7D26EB);

  static const Color textPrimary = Color(0xFF6A0DAD);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPurple = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFEAEAEA);
  static const Color divider = Color(0xFFE6E6E6);

  static const Color facebook = Color(0xFF1877F2);
}
