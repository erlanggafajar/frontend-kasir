import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../styles/color_style.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.home,
            (route) => false,
          );
          break;
        case 1:
          Navigator.pushNamed(context, RouteNames.transaksi);
          break;
        case 2:
          Navigator.pushNamed(context, RouteNames.riwayat);
          break;
        case 3:
          Navigator.pushNamed(context, RouteNames.pengaturan);
          break;
      }
    } else {
      // KASIR
      switch (index) {
        case 0:
          Navigator.pushNamedAndRemoveUntil(
            context,
            RouteNames.home,
            (route) => false,
          );
          break;
        case 1:
          Navigator.pushNamed(context, RouteNames.transaksi);
          break;
        case 2:
          Navigator.pushNamed(context, RouteNames.riwayat);
          break;
        case 3:
          Navigator.pushNamed(context, RouteNames.pengaturan);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final bool isAdmin = user?.hakAkses == 'ADMIN';

    final List<Map<String, dynamic>> navItems = isAdmin
        ? [
            {'icon': Icons.home_rounded, 'label': 'Home'},
            {'icon': Icons.point_of_sale_rounded, 'label': 'Transaksi'},
            {'icon': Icons.history_rounded, 'label': 'Riwayat'},
            {'icon': Icons.settings_rounded, 'label': 'Pengaturan'},
          ]
        : [
            {'icon': Icons.home_rounded, 'label': 'Home'},
            {'icon': Icons.point_of_sale_rounded, 'label': 'Transaksi'},
            {'icon': Icons.history_rounded, 'label': 'Riwayat'},
            {'icon': Icons.settings_rounded, 'label': 'Pengaturan'},
          ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              navItems.length,
              (index) => _buildNavItem(
                context,
                icon: navItems[index]['icon'],
                label: navItems[index]['label'],
                index: index,
                isSelected: currentIndex == index,
                isAdmin: isAdmin,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required bool isAdmin,
  }) {
    return Flexible(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context, index, isAdmin),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minWidth: 60, maxWidth: 90),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.darkgreen.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.darkgreen.withValues(alpha: 0.5),
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
