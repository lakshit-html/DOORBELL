import 'package:flutter/material.dart';

/// DoorBell brand palette — White + Light Green (#90EE90) as specified.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF34C759); // vivid, accessible green
  static const Color primaryLight = Color(0xFF90EE90); // brand light green
  static const Color primaryDark = Color(0xFF1E9E4A);
  static const Color accent = Color(0xFF00B894);

  static const Color background = Color(0xFFF7FBF7);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF1C40F);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  static const Color border = Color(0xFFE5E7EB);
  static const Color shimmerBase = Color(0xFFEAEAEA);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  /// Glassmorphism tints.
  static Color glassFill = Colors.white.withValues(alpha: 0.55);
  static Color glassBorder = Colors.white.withValues(alpha: 0.40);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
