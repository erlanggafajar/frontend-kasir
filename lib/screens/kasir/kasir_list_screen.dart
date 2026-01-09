import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../providers/kasir_provider.dart';
import '../../providers/auth_provider.dart';
import '../../styles/color_style.dart';
import 'kasir_form_screen.dart';
import 'kasir_edit_screen.dart';
import '../../models/kasir_model.dart';

class KasirListScreen extends StatefulWidget {
  const KasirListScreen({super.key});

  @override
  State<KasirListScreen> createState() => _KasirListScreenState();
}

class _KasirListScreenState extends State<KasirListScreen> {
  late KasirProvider _kasirProvider;
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final auth = context.read<AuthProvider>();

    if (auth.token == null) return;

    _kasirProvider = KasirProvider();
    _kasirProvider.fetchKasir(token: auth.token!);

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _kasirProvider,
      child: AppScaffold(
        title: 'Kelola Akun Kasir',
        currentIndex: 3,
        body: Consumer<KasirProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.kasirList.isEmpty) {
              return _emptyState();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      provider.searchKasir(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama kasir...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child:
                      provider.filteredKasirList.isEmpty &&
                          _searchController.text.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Kasir tidak ditemukan',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _searchController.text.isEmpty
                              ? provider.kasirList.length
                              : provider.filteredKasirList.length,
                          itemBuilder: (_, i) {
                            final kasir = _searchController.text.isEmpty
                                ? provider.kasirList[i]
                                : provider.filteredKasirList[i];
                            return _kasirCard(context, kasir);
                          },
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          child: const Icon(Icons.add),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: _kasirProvider,
                  child: const KasirFormScreen(),
                ),
              ),
            );

            // Store context before async gap
            final scaffoldContext = context;
            Future.microtask(() {
              if (mounted) {
                final authProvider = scaffoldContext.read<AuthProvider>();
                if (mounted) {
                  _kasirProvider.fetchKasir(token: authProvider.token!);
                }
              }
            });
          },
        ),
      ),
    );
  }

  // =========================
  // CARD KASIR
  // =========================
  Widget _kasirCard(BuildContext context, KasirModel kasir) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.person, color: AppColors.primary),
        ),
        title: Text(
          kasir.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(kasir.email),
        trailing: const Icon(Icons.more_vert),
        onTap: () => _showActionSheet(context, kasir),
      ),
    );
  }

  // =========================
  // ACTION SHEET (MODERN)
  // =========================
  void _showActionSheet(BuildContext context, KasirModel kasir) {
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
            _sheetItem(
              icon: Icons.edit,
              title: 'Edit Akun',
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KasirEditScreen(kasir: kasir),
                  ),
                );
                // Refresh data after returning from edit
                if (mounted) {
                  final authProvider = context.read<AuthProvider>();
                  final token = authProvider.token!;
                  if (mounted) {
                    _kasirProvider.fetchKasir(token: token);
                  }
                }
              },
            ),
            _sheetItem(
              icon: Icons.delete,
              title: 'Hapus Akun',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, kasir);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  // =========================
  // DELETE CONFIRMATION
  // =========================
  void _confirmDelete(BuildContext context, KasirModel kasir) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun Kasir'),
        content: Text('Yakin ingin menghapus akun kasir "${kasir.name}"?'),
        actions: [
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
            onPressed: () {
              // Store context before async gap
              final dialogContext = context;
              Future.microtask(() async {
                if (mounted) {
                  final authProvider = dialogContext.read<AuthProvider>();
                  final token = authProvider.token!;
                  if (mounted) {
                    await dialogContext.read<KasirProvider>().deleteKasir(
                      id: kasir.id,
                      token: token,
                    );
                  }
                  if (mounted) {
                    Navigator.pop(dialogContext);
                  }
                }
              });
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // EMPTY STATE
  // =========================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada akun kasir',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _kasirProvider.dispose();
    super.dispose();
  }
}
