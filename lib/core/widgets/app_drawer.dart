import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../navigation/route_names.dart';
import '../../styles/color_style.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final bool isAdmin = user?.hakAkses == 'ADMIN';

    return Drawer(
      backgroundColor: AppColors.white,
      child: Column(
        children: [
          _drawerHeader(user),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: RouteNames.home,
                ),
                if (isAdmin) ...[
                  const Divider(height: 8),
                  _drawerItem(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Manajemen Produk',
                    route: RouteNames.produkList,
                  ),
                  const Divider(height: 8),
                  _drawerItem(
                    context,
                    icon: Icons.settings,
                    title: 'Pengaturan',
                    route: RouteNames.pengaturan,
                  ),
                  const Divider(height: 8),
                  _drawerItem(
                    context,
                    icon: Icons.supervisor_account,
                    title: 'Kelola Akun Kasir',
                    route: RouteNames.kelolaKasir,
                  ),
                  const Divider(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HEADER
  // =========================
  Widget _drawerHeader(dynamic user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
      decoration: const BoxDecoration(color: AppColors.primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.white,
            child: Icon(Icons.person, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? '',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user?.hakAkses ?? '',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // DRAWER ITEM
  // =========================
  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.darkgreen,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }
}
