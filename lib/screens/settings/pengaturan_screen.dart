import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../styles/color_style.dart';
import '../../services/wifi_service.dart';
import '../../core/navigation/route_names.dart';
import 'wifi_settings_screen.dart';
import 'about_screen.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  String _selectedLanguage = 'id'; // Default language

  // WiFi Information
  String _wifiName = 'Kasir-WiFi';
  String _wifiPassword = 'Kasir123456';
  String _wifiSecurity = 'Super Kuat';
  bool _isWiFiConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadWiFiSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Load WiFi settings from SharedPreferences
  Future<void> _loadWiFiSettings() async {
    try {
      final isConfigured = await WiFiService.isWiFiConfigured();
      final wifiSettings = await WiFiService.getWiFiSettings();
      setState(() {
        _isWiFiConfigured = isConfigured;
        _wifiName = wifiSettings['name']!;
        _wifiPassword = wifiSettings['password']!;
        _wifiSecurity = wifiSettings['security']!;
      });
    } catch (e) {
      debugPrint('Error loading WiFi settings: $e');
      // Keep default values if loading fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    debugPrint('DEBUG: PengaturanScreen - User is null: ${user == null}');
    if (user != null) {
      debugPrint('DEBUG: PengaturanScreen - User hakAkses: ${user.hakAkses}');
      debugPrint('DEBUG: PengaturanScreen - User name: ${user.name}');
    }

    if (user == null ||
        (user.hakAkses != 'ADMIN' && user.hakAkses != 'KASIR')) {
      debugPrint('DEBUG: PengaturanScreen - Access denied');
      return const Scaffold(
        body: Center(
          child: Text(
            'Anda tidak memiliki akses ke halaman ini',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    debugPrint('DEBUG: PengaturanScreen - Access granted');

    return AppScaffold(
      title: 'Pengaturan',
      currentIndex: 3,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // WiFi Information Section
          _buildSection(
            title: 'Informasi WiFi',
            icon: Icons.wifi,
            children: [_buildWiFiCard(context)],
          ),

          const SizedBox(height: 24),

          // System Settings Section
          _buildSection(
            title: 'Pengaturan User',
            icon: Icons.settings,
            children: [
              _buildSettingItem(
                context,
                icon: Icons.person,
                title: 'Pengaturan User',
                subtitle: 'Kelola akun anda',
                onTap: () {
                  Navigator.of(context).pushNamed(RouteNames.userSettings);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // App Settings Section
          _buildSection(
            title: 'Pengaturan Aplikasi',
            icon: Icons.phone_android,
            children: [
              // _buildSettingItem(
              //   context,
              //   icon: Icons.notifications,
              //   title: 'Notifikasi',
              //   subtitle: 'Pengaturan notifikasi aplikasi',
              //   onTap: () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Fitur akan segera hadir')),
              //     );
              //   },
              // ),
              _buildSettingItem(
                context,
                icon: Icons.wb_sunny,
                title: 'Tema Aplikasi',
                subtitle: 'Ubah tema terang/gelap',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur akan segera hadir')),
                  );
                },
              ),

              _buildSettingItem(
                context,
                icon: Icons.translate,
                title: _selectedLanguage == 'id'
                    ? 'Ubah Bahasa'
                    : 'Change Language',
                subtitle: _selectedLanguage == 'id'
                    ? 'Ubah bahasa aplikasi'
                    : 'Change application language',
                trailing: DropdownButton<String>(
                  value: _selectedLanguage,
                  isDense: true,
                  isExpanded: false,
                  style: const TextStyle(fontSize: 12),
                  dropdownColor: Colors.white,
                  elevation: 2,
                  iconSize: 20,
                  itemHeight: 48,
                  menuMaxHeight: 120,
                  items: const [
                    DropdownMenuItem(
                      value: 'id',
                      child: Text(
                        '🇮🇩 Indonesia',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(
                        '🇬🇧 English',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLanguage = newValue;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _selectedLanguage == 'id'
                                ? 'Bahasa diubah ke Indonesia'
                                : 'Language changed to English',
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),

              _buildSettingItem(
                context,
                icon: Icons.info,
                title: 'Tentang Aplikasi',
                subtitle: 'Informasi versi aplikasi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildWiFiCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WiFi Icon and Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isWiFiConfigured
                        ? AppColors.primary
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isWiFiConfigured ? Icons.wifi : Icons.wifi_off,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isWiFiConfigured
                            ? 'WiFi Kasir'
                            : 'WiFi Belum Dikonfigurasi',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isWiFiConfigured
                            ? 'Bagikan informasi WiFi kepada pelanggan'
                            : 'Atur WiFi untuk memberikan informasi kepada pelanggan',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showWiFiActionSheet(context),
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Menu Aksi',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // WiFi Details or Setup Prompt
            if (_isWiFiConfigured) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildWiFiInfoRow('Nama Network', _wifiName),
                    const Divider(height: 1),
                    _buildWiFiInfoRow('Password', _wifiPassword),
                    const Divider(height: 1),
                    _buildWiFiInfoRow('Keamanan', _wifiSecurity),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Pengaturan WiFi hanya dapat dilakukan sekali',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pastikan data yang Anda masukkan sudah benar, karena tidak dapat diubah setelah disimpan.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            if (_isWiFiConfigured) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _copyWiFiInfo(context),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('SALIN INFO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareWiFiInfo(context),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('BAGIKAN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _setupWiFi(context),
                  icon: const Icon(Icons.wifi_tethering, size: 18),
                  label: const Text('ATUR WIFI SEKARANG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWiFiInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  // Copy individual value
                },
                icon: Icon(Icons.copy, size: 16, color: AppColors.primary),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // =========================
  // ACTION SHEET (MODERN)
  // =========================
  void _showWiFiActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // WiFi Status Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isWiFiConfigured
                          ? AppColors.primary
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isWiFiConfigured ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isWiFiConfigured
                              ? 'WiFi Kasir'
                              : 'WiFi Belum Dikonfigurasi',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _isWiFiName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: Colors.grey[300]),

            // Action Items
            if (_isWiFiConfigured) ...[
              _sheetItem(
                icon: Icons.qr_code,
                title: 'Tampilkan QR Code',
                onTap: () {
                  Navigator.pop(context);
                  _showWiFiInfo(context);
                },
              ),
              _sheetItem(
                icon: Icons.edit,
                title: 'Edit WiFi',
                onTap: () {
                  Navigator.pop(context);
                  _editWiFiSettings(context);
                },
              ),
              _sheetItem(
                icon: Icons.delete,
                title: 'Hapus WiFi',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _deleteWiFiSettings(context);
                },
              ),
            ] else ...[
              _sheetItem(
                icon: Icons.settings,
                title: 'Atur WiFi',
                onTap: () {
                  Navigator.pop(context);
                  _setupWiFi(context);
                },
              ),
            ],

            // Bottom padding
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Helper method for sheet items
  Widget _sheetItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color != null
              ? color.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  String get _isWiFiName => _isWiFiConfigured ? _wifiName : 'Belum diatur';

  void _showWiFiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Code Placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 80, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text(
                      'QR Code WiFi',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan QR Code untuk terhubung ke WiFi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('TUTUP'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setupWiFi(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const WiFiSettingsScreen()));
    // Refresh state after setting up WiFi
    _loadWiFiSettings();
  }

  void _editWiFiSettings(BuildContext context) {
    // Admin can edit WiFi settings (force update)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit WiFi Settings'),
        content: const Text(
          'Sebagai admin, Anda dapat mengubah pengaturan WiFi. Apakah Anda yakin ingin melanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const WiFiSettingsScreen(),
                    ),
                  )
                  .then((_) => _loadWiFiSettings());
            },
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _deleteWiFiSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.red, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hapus Pengaturan WiFi',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apakah Anda yakin ingin menghapus pengaturan WiFi?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tindakan ini akan:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                ...[
                  '• Menghapus nama dan password WiFi',
                  '• WiFi perlu dikonfigurasi ulang',
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(item),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Setelah dihapus, pengaturan WiFi hanya dapat dilakukan sekali lagi.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await WiFiService.deleteWiFiSettings();
                await _loadWiFiSettings(); // Refresh state

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pengaturan WiFi berhasil dihapus!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus WiFi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _copyWiFiInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informasi WiFi disalin!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareWiFiInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur bagikan akan segera hadir'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
