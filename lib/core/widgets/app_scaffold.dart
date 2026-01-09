import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../navigation/route_names.dart';
import '../../styles/color_style.dart';
import 'bottom_nav.dart';
import 'app_drawer.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final String title;
  final bool showBottomNav;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.title,
    this.showBottomNav = true,
    this.floatingActionButton,
  });

  // =========================
  // LOGOUT CONFIRMATION
  // =========================
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.red, size: 25),
            const SizedBox(width: 8),
            const Text(
              'Konfirmasi Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.red,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.darkgreen),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              Navigator.pop(context);

              // Small delay to ensure dialog is fully closed
              await Future.delayed(const Duration(milliseconds: 100));

              if (context.mounted) {
                authProvider.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                  (route) => false,
                );
              }
            },
            child: const Text('Ya, Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: AppColors.red,
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: body,
      bottomNavigationBar: showBottomNav
          ? AppBottomNav(currentIndex: currentIndex)
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
