import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../core/widgets/app_scaffold.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../styles/color_style.dart';
import '../qr/qr_scanner_screen.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  Set<int> _selectedProducts = {};
  TextEditingController? _searchController;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // Initialize data after the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _searchController?.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // =========================
  void _showActionSheet(BuildContext context, ProductModel product) {
    final authProvider = context.read<AuthProvider>();
    final isAdmin = authProvider.isAdmin;

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
              icon: Icons.info_outline,
              title: 'Detail Produk',
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(product.id);
              },
            ),
            if (isAdmin) ...[
              _sheetItem(
                icon: Icons.edit,
                title: 'Edit Produk',
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductFormScreen(product: product),
                    ),
                  );
                  // Refresh data after returning from edit
                  if (mounted) {
                    _refreshData();
                  }
                },
              ),
              _sheetItem(
                icon: Icons.delete,
                title: 'Hapus Produk',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(product);
                },
              ),
            ],
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

  Future<void> _refreshData() async {
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      await context.read<ProductProvider>().fetchProducts(token, refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manajemen Produk',
      currentIndex: 1,
      body: Column(
        children: [
          // SEKSI PENCARIAN & FILTER
          _buildHeaderFilter(),

          // Hapus Semua Option (ADMIN ONLY)
          Consumer2<ProductProvider, AuthProvider>(
            builder: (context, productProvider, authProvider, _) {
              if (productProvider.products.isEmpty || !authProvider.isAdmin) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value:
                          _selectedProducts.length ==
                          productProvider.products.length,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            // Select all products
                            _selectedProducts = productProvider.products
                                .map((p) => p.id)
                                .toSet();
                          } else {
                            // Deselect all products
                            _selectedProducts.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedProducts.isEmpty
                            ? 'Pilih semua produk (${productProvider.products.length})'
                            : 'Terpilih ${_selectedProducts.length} dari ${productProvider.products.length} produk',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_selectedProducts.isNotEmpty)
                      IconButton(
                        onPressed: _showDeleteSelectedConfirmation,
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Hapus yang dipilih',
                      ),
                  ],
                ),
              );
            },
          ),

          // DAFTAR PRODUK
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (!provider.isLoadingMore &&
                        !provider.hasReachedMax &&
                        scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                      // Load more products when user reaches the bottom
                      final token = context.read<AuthProvider>().token;
                      if (token != null) {
                        provider.loadMoreProducts(token);
                      }
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount:
                          provider.filtered.length +
                          (provider.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.filtered.length &&
                            provider.isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final product = provider.filtered[index];
                        return _buildProductCard(product);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFabGroup(),
    );
  }

  Widget _buildHeaderFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) {
              // Cancel previous timer
              _searchTimer?.cancel();

              // Use debounced search to avoid too many API calls
              context.read<ProductProvider>().search(v);

              // Trigger API search after a short delay
              _searchTimer = Timer(const Duration(milliseconds: 500), () {
                if (mounted) {
                  final token = context.read<AuthProvider>().token;
                  if (token != null) {
                    context.read<ProductProvider>().performSearch(token, v);
                  }
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Cari nama atau kode barang...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                ),
                onPressed: () async {
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QrScannerScreen(),
                    ),
                  );

                  if (result != null && mounted) {
                    _searchController?.text = result;
                    final token = context.read<AuthProvider>().token;
                    if (token != null) {
                      context.read<ProductProvider>().performSearch(
                        token,
                        result,
                      );
                    }
                  }
                },
              ),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              // Check the current stock filter state
              final stockFilter = provider.stockFilter;
              final isAvailableOnly = stockFilter == 1;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAvailableOnly ? "Hanya stok tersedia" : "Stock habis",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch.adaptive(
                    value: isAvailableOnly,
                    onChanged: (val) => provider.toggleAvailable(val),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel p) {
    final isOutOfStock = p.stok <= 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => _showActionSheet(context, p),
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isOutOfStock
                ? Colors.red[50]
                : const Color(0xFF007211).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: isOutOfStock ? Colors.red : AppColors.primary,
          ),
        ),
        title: Text(
          p.nama,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          'Kode: ${p.kodeBarang}\n${_formatCurrency(p.harga)}',
          style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Stok',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  p.stok.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? Colors.red : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showActionSheet(context, p),
              tooltip: 'Opsi lainnya',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        final hasSearch = provider.query.isNotEmpty;

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasSearch ? Icons.search_off : Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                hasSearch ? 'Produk tidak ditemukan' : 'Produk tidak ditemukan',
                style: TextStyle(color: Colors.grey[600]),
              ),
              if (hasSearch)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Coba kata kunci lain',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _searchController?.clear();
                  context.read<ProductProvider>().search('');
                  _refreshData();
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFabGroup() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Only show FAB for ADMIN
        if (!authProvider.isAdmin) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'add',
              backgroundColor: AppColors.primary,
              onPressed: () => _navigateToForm(),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        );
      },
    );
  }

  // --- LOGIKA NAVIGASI & AKSI ---

  void _navigateToDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: id)),
    );
  }

  void _navigateToForm({ProductModel? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  void _showDeleteConfirmation(ProductModel product) {
    // Check if user is ADMIN
    if (!context.read<AuthProvider>().isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya admin yang dapat menghapus produk'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              _deleteProduct(product.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteSelectedConfirmation() {
    // Check if user is ADMIN
    if (!context.read<AuthProvider>().isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hanya admin yang dapat menghapus produk'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedCount = _selectedProducts.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk Terpilih?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus $selectedCount produk yang dipilih? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              _deleteSelectedProducts();
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelectedProducts() async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = context.read<AuthProvider>().token!;
      final provider = context.read<ProductProvider>();

      // Delete selected products
      for (final productId in _selectedProducts) {
        await provider.deleteProduct(productId, token);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        setState(() {
          _selectedProducts.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk terpilih berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(int id) async {
    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final token = context.read<AuthProvider>().token!;
      await context.read<ProductProvider>().deleteProduct(id, token);

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
