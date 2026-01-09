import 'package:flutter/material.dart';
import 'color_style.dart';

class AppInputStyle {
  static InputDecoration modern({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.darkgreen),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.white,
      floatingLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.darkgreen,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  static InputDecoration modernWithCursor({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.darkgreen),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.white,
      floatingLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.darkgreen,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkgreen, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkgreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  static TextStyle inputStyle() {
    return const TextStyle(color: Colors.black, fontSize: 14);
  }
}
