import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/navigation/route_names.dart';
import '../../styles/color_style.dart';
import '../settings/user_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllMenus = false;
  int _totalRevenue = 0;
  bool _showRevenue = false;

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    try {
      final transactionProvider = context.read<TransactionProvider>();
      await transactionProvider.loadTransactions(context: context);

      final user = context.read<AuthProvider>().user;
      final transactions = transactionProvider.transactions;

      int total = 0;
      for (final transaction in transactions) {
        if (user?.hakAkses == 'ADMIN') {
          // Admin sees all revenue
          total += transaction.totalHarga;
        } else if (user?.hakAkses == 'KASIR') {
          // Kasir only sees their own revenue
          if (transaction.userId == user?.id ||
              transaction.namaKasir.toLowerCase() == user?.name.toLowerCase()) {
            total += transaction.totalHarga;
          }
        }
      }

      setState(() {
        _totalRevenue = total;
      });
    } catch (e) {
      debugPrint('Error loading revenue data: $e');
    }
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return AppScaffold(
      title: 'Dashboard',
      currentIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // REVENUE CARD
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.9),
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Column 1: Icon
                      Expanded(
                        flex: 1,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.monetization_on,
                                color: AppColors.white,
                                size: 25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Column 2: Revenue Information
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Role indicator with refresh button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(
                                      alpha: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        context
                                                    .watch<AuthProvider>()
                                                    .user
                                                    ?.hakAkses ==
                                                'ADMIN'
                                            ? Icons.done_all
                                            : Icons.done,
                                        color: AppColors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        context
                                                    .watch<AuthProvider>()
                                                    .user
                                                    ?.hakAkses ==
                                                'ADMIN'
                                            ? 'Saat ini'
                                            : 'Total keseluruhan',
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Refresh button
                                GestureDetector(
                                  onTap: () async {
                                    await _loadRevenueData();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.refresh,
                                      color: AppColors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user?.hakAkses == 'ADMIN'
                                  ? 'Total seluruh omset / pendapatan'
                                  : 'Pendapatan dihasilkan',
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                // If revenue is 0, try to reload data first
                                if (_totalRevenue == 0) {
                                  await _loadRevenueData();
                                }
                                setState(() {
                                  _showRevenue = !_showRevenue;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _showRevenue
                                      ? Text(
                                          _formatCurrency(_totalRevenue),
                                          style: const TextStyle(
                                            color: AppColors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Container(
                                          height: 28,
                                          width: 70,
                                          child: const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              '󠁯•󠁏󠁏󠁯•󠁏󠁏󠁯•󠁏󠁏󠁯•󠁏󠁏󠁯•󠁏󠁏󠁯•󠁏󠁏󠁯•󠁏󠁏󠁯•󠁏󠁏󠁯•󠁏󠁏󠁯•󠁏󠁏',
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _showRevenue
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: AppColors.white.withValues(
                                      alpha: 0.8,
                                    ),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // =========================
            // QUICK ACTIONS TITLE
            // =========================
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                color: AppColors.darkgreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // =========================
            // QUICK ACTIONS CARD
            // =========================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.darkgreen.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Builder(
                builder: (context) {
                  final mainMenus = _getMainMenus(user);
                  final additionalMenus = _getAdditionalMenus(user);
                  final totalMenus = mainMenus.length + additionalMenus.length;
                  final hasMoreThanFour = totalMenus > 10;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Use 3 columns for better layout
                      final crossAxisCount = 3;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main menus grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1.5,
                            children: mainMenus,
                          ),

                          // Additional menus grid (when expanded or if total <= 4)
                          if (additionalMenus.isNotEmpty &&
                              (_showAllMenus || !hasMoreThanFour)) ...[
                            const SizedBox(height: 6),
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                              childAspectRatio: 1.5,
                              children: additionalMenus,
                            ),
                          ],

                          // See all button (only if total menus > 4)
                          if (hasMoreThanFour) ...[
                            const SizedBox(height: 6),
                            _buildSeeAllButton(),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // =========================
  // GET MAIN MENUS
  // =========================
  List<Widget> _getMainMenus(dynamic user) {
    List<Widget> menus = [];

    menus.add(
      _quickActionItem(
        context,
        icon: Icons.point_of_sale,
        title: 'Transaksi Baru',
        onTap: () => Navigator.pushNamed(context, RouteNames.transaksi),
      ),
    );

    menus.add(
      _quickActionItem(
        context,
        icon: user?.hakAkses == 'KASIR' ? Icons.inventory_2 : Icons.add_box,
        title: user?.hakAkses == 'KASIR' ? 'Lihat Produk' : 'Tambah Produk',
        onTap: () => Navigator.pushNamed(
          context,
          user?.hakAkses == 'KASIR' ? RouteNames.produk : RouteNames.produkForm,
        ),
      ),
    );

    menus.add(
      _quickActionItem(
        context,
        icon: Icons.history,
        title: 'Riwayat Hari Ini',
        onTap: () => Navigator.pushNamed(context, RouteNames.riwayat),
      ),
    );

    return menus;
  }

  // =========================
  // GET ADDITIONAL MENUS
  // =========================
  List<Widget> _getAdditionalMenus(dynamic user) {
    List<Widget> menus = [];

    if (user?.hakAkses == 'ADMIN') {
      menus.add(
        _quickActionItem(
          context,
          icon: Icons.people,
          title: 'Kelola User',
          onTap: () => Navigator.pushNamed(context, RouteNames.kelolaKasir),
        ),
      );
    }

    // Add HR menus for all users
    menus.add(
      _quickActionItem(
        context,
        icon: Icons.fingerprint,
        title: user?.hakAkses == 'ADMIN' ? 'Lihat Kehadiran' : 'Kehadiran',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu ini masih dalam tahap pengembangan'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );

    menus.add(
      _quickActionItem(
        context,
        icon: Icons.account_balance_wallet,
        title: 'Penggajian',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Menu ini masih dalam tahap pengembangan'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );

    // Add fourth menu for KASIR to complete 3x2 grid
    if (user?.hakAkses == 'KASIR') {
      menus.add(
        _quickActionItem(
          context,
          icon: Icons.account_circle,
          title: 'Edit Profile',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserSettingsScreen(),
                settings: const RouteSettings(arguments: 'edit_profile_only'),
              ),
            );
          },
        ),
      );
    }

    return menus;
  }

  // =========================
  // BUILD SEE ALL BUTTON
  // =========================
  Widget _buildSeeAllButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          setState(() {
            _showAllMenus = !_showAllMenus;
          });
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showAllMenus ? 'Tutup' : 'Lihat Semua',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _showAllMenus
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // QUICK ACTION ITEM - Professional Design
  // =========================
  Widget _quickActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkgreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
