class RouteNames {
  RouteNames._();

  // Root & Auth
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Main
  static const String home = '/home';

  // Kasir Core
  static const String transaksi = '/transaksi';
  static const String transaksiBaru = '/transaksi/baru';
  static const String transaksiHistory = '/transaksi/riwayat';
  static const String transaksiDetail = '/transaksi/detail';
  static const String produk = '/produk';
  static const String riwayat = '/riwayat';
  static const kelolaKasir = '/kelola-kasir';

  // Produk
  static const String produkList = '/produk';
  static const String produkDetail = '/produk/detail';
  static const String produkForm = '/produk/form';

  // System
  static const String pengaturan = '/pengaturan';
  static const String userSettings = '/pengaturan/user';

  // Admin Only (future)
  static const String users = '/users';
  static const String laporan = '/laporan';
}
