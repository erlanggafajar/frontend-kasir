import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'route_names.dart';

// Models
import '../../models/transaction_model.dart';

// Screens
import '../../screens/home/home_screen.dart';
import '../../screens/transaksi/transaction_screen.dart';
import '../../screens/transaksi/transaction_history_screen.dart';
import '../../screens/transaksi/transaction_detail.screen.dart';
import '../../screens/riwayat/riwayat_screen.dart';
import '../../screens/settings/pengaturan_screen.dart';
import '../../screens/settings/user_settings_screen.dart';
import '../../screens/kasir/kasir_list_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/common/unauthorized_screen.dart';
import '../../screens/produk/product_list_screen.dart';
import '../../screens/produk/product_detail_screen.dart';
import '../../screens/produk/product_form_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return _page(const HomeScreen());

      // ================= PRODUK =================
      case RouteNames.produkList:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());

      case RouteNames.produkDetail:
        final productId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: productId),
        );

      case RouteNames.produkForm:
        return MaterialPageRoute(
          builder: (_) =>
              ProductFormScreen(product: settings.arguments as dynamic),
        );

      // ================= TRANSAKSI =================
      case RouteNames.transaksi:
      case RouteNames.transaksiBaru:
        return _page(const TransactionScreen());
      case RouteNames.transaksiHistory:
        return _page(const TransactionHistoryScreen());
      case RouteNames.riwayat:
        return _page(const RiwayatScreen());
      case RouteNames.transaksiDetail:
        final args = settings.arguments as Map<String, dynamic>;
        final transactionId = args['transactionId'] as int?;
        final transaction = args['transaction'] as Transaction?;
        final displayNumber = args['displayNumber'] as int;
        return _page(
          TransactionDetailScreen(
            transactionId: transactionId,
            transaction: transaction,
            displayNumber: displayNumber,
          ),
        );

      case RouteNames.pengaturan:
        return _authOnly(settings, const PengaturanScreen());

      case RouteNames.userSettings:
        return _authOnly(settings, const UserSettingsScreen());

      case RouteNames.kelolaKasir:
        return _adminOnly(settings, const KasirListScreen());

      case RouteNames.login:
        return _page(const LoginScreen());

      default:
        return _page(
          const Scaffold(body: Center(child: Text('Route tidak ditemukan'))),
        );
    }
  }

  // =========================
  // NORMAL PAGE
  // =========================
  static PageRoute _page(Widget child) {
    return MaterialPageRoute(builder: (_) => child);
  }

  // =========================
  // ADMIN ONLY GUARD
  // =========================
  static PageRoute _adminOnly(RouteSettings settings, Widget page) {
    return MaterialPageRoute(
      builder: (context) {
        final auth = context.read<AuthProvider>();
        final user = auth.user;

        if (user == null) {
          return const LoginScreen();
        }

        if (user.hakAkses != 'ADMIN') {
          return const UnauthorizedScreen();
        }

        return page;
      },
    );
  }

  // =========================
  // AUTH ONLY GUARD (ADMIN + KASIR)
  // =========================
  static PageRoute _authOnly(RouteSettings settings, Widget page) {
    return MaterialPageRoute(
      builder: (context) {
        final auth = context.read<AuthProvider>();
        final user = auth.user;

        debugPrint('DEBUG: User is null: ${user == null}');
        if (user != null) {
          debugPrint('DEBUG: User hakAkses: ${user.hakAkses}');
          debugPrint('DEBUG: User name: ${user.name}');
        }

        if (user == null) {
          return const LoginScreen();
        }

        if (user.hakAkses != 'ADMIN' && user.hakAkses != 'KASIR') {
          debugPrint('DEBUG: Access denied for hakAkses: ${user.hakAkses}');
          return const UnauthorizedScreen();
        }

        debugPrint('DEBUG: Access granted for hakAkses: ${user.hakAkses}');
        return page;
      },
    );
  }
}
