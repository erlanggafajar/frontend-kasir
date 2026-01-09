import 'package:flutter/material.dart';
import 'color_style.dart';

class AppButtonStyle {
  static ButtonStyle primary = ButtonStyle(
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    // Efek hover lebih terang
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) {
        return Colors.white.withValues(alpha: 0.2);
      }
      if (states.contains(WidgetState.pressed)) {
        return Colors.white.withValues(alpha: 0.3);
      }
      return null;
    }),

    // Background color
    backgroundColor: WidgetStatePropertyAll(AppColors.primary),
    foregroundColor: WidgetStatePropertyAll(AppColors.white),
    elevation: const WidgetStatePropertyAll(6),
    shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.2)),
  );
}
