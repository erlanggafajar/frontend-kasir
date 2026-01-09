import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/navigation/route_names.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../models/product_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../styles/color_style.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _productScrollController = ScrollController();

  final ValueNotifier<int> _processingDotCount = ValueNotifier<int>(1);
  Timer? _processingTimer;
  Timer? _searchDebounceTimer;
  DateTime? _processingStartedAt;
  bool _holdProcessing = false;

  // Animation controllers for enhanced processing animation
  late AnimationController _processingAnimationController;

  bool _controllersInitialized = false;

  void _onScroll() {
    if (!_productScrollController.hasClients) return;

    final maxScroll = _productScrollController.position.maxScrollExtent;
    final currentScroll = _productScrollController.position.pixels;
    final delta = 200.0; // Load more when 200px from bottom

    if (maxScroll - currentScroll <= delta) {
      final productProvider = context.read<ProductProvider>();
      final authProvider = context.read<AuthProvider>();

      if (!productProvider.isLoadingMore &&
          !productProvider.hasReachedMax &&
          authProvider.token != null) {
        productProvider.loadMoreProducts(authProvider.token!);
      }
    }
  }

  void _performSearchWithDebounce(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final productProvider = context.read<ProductProvider>();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.token != null) {
        productProvider.performSearch(authProvider.token!, query);
      }
    });
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  List<ProductModel> _sortProductsForTransaction(List<ProductModel> products) {
    final sortedProducts = List<ProductModel>.from(products);

    sortedProducts.sort((a, b) {
      int comparison;
      switch (context.read<ProductProvider>().sortBy) {
        case 'nama':
          comparison = a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
          break;
        case 'kode':
          comparison = a.kodeBarang.toLowerCase().compareTo(
            b.kodeBarang.toLowerCase(),
          );
          break;
        case 'harga':
          comparison = a.harga.compareTo(b.harga);
          break;
        case 'stok':
          comparison = a.stok.compareTo(b.stok);
          break;
        default:
          comparison = a.nama.toLowerCase().compareTo(b.nama.toLowerCase());
      }

      return context.read<ProductProvider>().isAscending
          ? comparison
          : -comparison;
    });

    return sortedProducts;
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _processingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _controllersInitialized = true;

    // Setup scroll listener for pagination
    _productScrollController.addListener(_onScroll);

    // Load products when the screen initializes
    Future.microtask(() {
      if (mounted) {
        final productProvider = context.read<ProductProvider>();
        if (productProvider.products.isEmpty) {
          final authProvider = context.read<AuthProvider>();
          if (authProvider.token != null) {
            productProvider.fetchProducts(authProvider.token!);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _processingAnimationController.dispose();
    _searchController.dispose();
    _productScrollController.dispose();
    _processingTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _processingDotCount.dispose();
    super.dispose();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer<ProductProvider>(
        builder: (context, provider, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Urutkan Produk',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Nama'),
              trailing: provider.sortBy == 'nama'
                  ? Icon(
                      provider.isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    )
                  : null,
              onTap: () {
                provider.setSort('nama');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Kode Barang'),
              trailing: provider.sortBy == 'kode'
                  ? Icon(
                      provider.isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    )
                  : null,
              onTap: () {
                provider.setSort('kode');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Harga'),
              trailing: provider.sortBy == 'harga'
                  ? Icon(
                      provider.isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    )
                  : null,
              onTap: () {
                provider.setSort('harga');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Stok'),
              trailing: provider.sortBy == 'stok'
                  ? Icon(
                      provider.isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    )
                  : null,
              onTap: () {
                provider.setSort('stok');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _startProcessingUi() {
    _processingStartedAt = DateTime.now();
    _holdProcessing = true;

    // Start animation only if controller is initialized
    if (_controllersInitialized) {
      _processingAnimationController.repeat(reverse: true);
    }

    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      final next = _processingDotCount.value >= 3
          ? 1
          : (_processingDotCount.value + 1);
      _processingDotCount.value = next;
    });

    if (mounted) setState(() {});
  }

  Future<void> _stopProcessingUi() async {
    final startedAt = _processingStartedAt;
    if (startedAt != null) {
      const minDuration = Duration(milliseconds: 800);
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    }

    // Stop animation only if controller is initialized
    if (_controllersInitialized) {
      _processingAnimationController.stop();
      _processingAnimationController.reset();
    }

    _processingTimer?.cancel();
    _processingTimer = null;
    _holdProcessing = false;
    _processingStartedAt = null;

    if (mounted) setState(() {});
  }

  Widget _processingLabel({double fontSize = 16}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: fontSize * 1.5,
          height: fontSize * 1.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'DIPROSES',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    return AppScaffold(
      title: 'Transaksi Baru',
      currentIndex: 1,
      body: isSmallScreen ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Search bar with history button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    // Trigger search with debouncing
                    _performSearchWithDebounce(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Sort button
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _showSortOptions,
                tooltip: 'Urutkan Produk',
              ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.token != null) {
                    context.read<ProductProvider>().fetchProducts(
                      authProvider.token!,
                      refresh: true,
                    );
                  }
                },
                tooltip: 'Refresh Produk',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),

        // Cart summary button
        Consumer<TransactionProvider>(
          builder: (context, transactionProvider, _) {
            if (transactionProvider.cartItems.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${transactionProvider.cartItems.length} item',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatCurrency(
                            transactionProvider.totalPrice.toInt(),
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _showMobileCart(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('Lihat Keranjang'),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Product count indicator
        Consumer<ProductProvider>(
          builder: (context, productProvider, _) {
            String statusText = '';
            if (productProvider.isLoadingMore) {
              statusText = ' (memuat lebih banyak...)';
            } else if (!productProvider.hasReachedMax &&
                productProvider.filtered.isNotEmpty) {
              statusText = ' (scroll untuk lebih banyak)';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menampilkan ${productProvider.filtered.length} produk$statusText',
                  style: TextStyle(
                    color: AppColors.darkgreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),

        // Product list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final authProvider = context.read<AuthProvider>();
              if (authProvider.token != null) {
                await context.read<ProductProvider>().fetchProducts(
                  authProvider.token!,
                  refresh: true,
                );
              }
            },
            child: _buildProductList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Search bar with history button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    // Trigger search with debouncing
                    _performSearchWithDebounce(value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  final authProvider = context.read<AuthProvider>();
                  if (authProvider.token != null) {
                    context.read<ProductProvider>().fetchProducts(
                      authProvider.token!,
                      refresh: true,
                    );
                  }
                },
                tooltip: 'Refresh Produk',
              ),
              const SizedBox(width: 8),
              // Sort button
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: _showSortOptions,
                tooltip: 'Urutkan Produk',
              ),
            ],
          ),
        ),

        // Product count indicator
        Consumer<ProductProvider>(
          builder: (context, productProvider, _) {
            String statusText = '';
            if (productProvider.isLoadingMore) {
              statusText = ' (memuat lebih banyak...)';
            } else if (!productProvider.hasReachedMax &&
                productProvider.filtered.isNotEmpty) {
              statusText = ' (scroll untuk lebih banyak)';
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Menampilkan ${productProvider.filtered.length} produk$statusText',
                  style: TextStyle(
                    color: AppColors.darkgreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),

        // Product list and cart
        Expanded(
          child: Row(
            children: [
              // Product list
              Expanded(
                flex: 2,
                child: RefreshIndicator(
                  onRefresh: () async {
                    final authProvider = context.read<AuthProvider>();
                    if (authProvider.token != null) {
                      await context.read<ProductProvider>().fetchProducts(
                        authProvider.token!,
                        refresh: true,
                      );
                    }
                  },
                  child: _buildProductList(),
                ),
              ),

              // Cart
              Container(
                width: 350,
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.grey[300]!)),
                ),
                child: _buildCart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductList() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.products.isEmpty && !productProvider.isLoading) {
          return const Center(child: Text('Tidak ada produk tersedia'));
        }

        var displayProducts = _sortProductsForTransaction(
          productProvider.filtered,
        );

        if (displayProducts.isEmpty) {
          return const Center(child: Text('Produk tidak ditemukan'));
        }

        final isSmallScreen = MediaQuery.of(context).size.width < 768;

        return NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification is ScrollEndNotification) {
              _onScroll();
            }
            return false;
          },
          child: SingleChildScrollView(
            controller: _productScrollController,
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isSmallScreen ? 2 : 3,
                    childAspectRatio: isSmallScreen ? 0.7 : 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: displayProducts.length,
                  itemBuilder: (context, index) {
                    final product = displayProducts[index];
                    return _buildProductCard(product, isSmallScreen);
                  },
                ),
                // Loading indicator at bottom
                if (productProvider.isLoadingMore)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product, bool isSmallScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product header with info
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product code
                        Text(
                          product.kodeBarang,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Product name
                        Text(
                          product.nama,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Stock status overlay
                    if (product.stok <= 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'HABIS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Quick add button
                    if (product.stok > 0)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: isSmallScreen ? 14 : 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      _formatCurrency(product.harga),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    // Stock info
                    Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          size: isSmallScreen ? 12 : 14,
                          color: product.stok > 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stok: ${product.stok}',
                          style: TextStyle(
                            color: product.stok > 0 ? Colors.green : Colors.red,
                            fontSize: isSmallScreen ? 9 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(ProductModel product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with animation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              // Success message
              const Text(
                'Berhasil Ditambahkan!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${product.nama} telah ditambahkan ke keranjang',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    // Auto-dismiss after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showTransactionSuccessDialog(Transaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20), // Reduced from 24 to 20
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success animation container
              Container(
                padding: const EdgeInsets.all(16), // Reduced from 20 to 16
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.1),
                      AppColors.primary.withValues(alpha: 0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 48, // Reduced from 56 to 48
                ),
              ),
              const SizedBox(height: 16), // Reduced from 20 to 16
              // Success title
              const Text(
                'Transaksi Berhasil!',
                style: TextStyle(
                  fontSize: 20, // Reduced from 22 to 20
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Transaction details
              Container(
                padding: const EdgeInsets.all(12), // Reduced from 16 to 12
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'No. Transaksi',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ), // Reduced from 14 to 13
                        ),
                        Flexible(
                          child: Text(
                            '#${transaction.id}',
                            style: const TextStyle(
                              fontSize: 13, // Reduced from 14 to 13
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ), // Reduced from 14 to 13
                        ),
                        Flexible(
                          child: Text(
                            _formatCurrency(transaction.totalHarga),
                            style: const TextStyle(
                              fontSize: 14, // Reduced from 16 to 14
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16), // Reduced from 20 to 16
              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      RouteNames.transaksiDetail,
                      arguments: {
                        'transaction': transaction,
                        'displayNumber':
                            1, // New transaction always shows as #1
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ), // Reduced from 16 to 14
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Reduced from 12 to 10
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 18,
                      ), // Added size constraint
                      SizedBox(width: 6), // Reduced from 8 to 6
                      Text(
                        'LIHAT DETAIL',
                        style: TextStyle(
                          fontSize: 14, // Reduced from 16 to 14
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10), // Reduced from 12 to 10
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ), // Reduced from 16 to 14
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Reduced from 12 to 10
                    ),
                  ),
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(
                      fontSize: 14, // Reduced from 16 to 14
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(ProductModel product) {
    if (product.stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk habis, tidak dapat ditambahkan ke keranjang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final transactionProvider = context.read<TransactionProvider>();
    transactionProvider.addToCart(
      TransactionItem.cart(
        productId: product.id,
        quantity: 1,
        productName: product.nama,
        price: product.harga.toDouble(),
      ),
    );

    // Show success dialog instead of snackbar
    _showSuccessDialog(product);
  }

  void _showMobileCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        snap: true,
        snapSizes: const [0.4, 0.6, 0.85],
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: _buildMobileCartContent(scrollController),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCartContent(ScrollController scrollController) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        final cartItems = transactionProvider.cartItems;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.withValues(alpha: 0.02)],
            ),
          ),
          child: Column(
            children: [
              // Handle bar with enhanced design
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Cart header with gradient background
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Keranjang',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${cartItems.length} item',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Cart items with enhanced design
              Expanded(
                child: cartItems.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Keranjang kosong',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tambahkan produk untuk memulai transaksi',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMobileCartItem(
                              item,
                              transactionProvider,
                            ),
                          );
                        },
                      ),
              ),
              // Checkout section with enhanced design
              if (cartItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Total price with enhanced design
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.1),
                              AppColors.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                _formatCurrency(
                                  transactionProvider.totalPrice.toInt(),
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Checkout button with enhanced design
                      Consumer<TransactionProvider>(
                        builder: (context, provider, _) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (!(provider.isLoading || _holdProcessing))
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: (provider.isLoading || _holdProcessing)
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _processPayment(
                                        provider,
                                        showProcessingDialog: true,
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (provider.isLoading || _holdProcessing)
                                    ? Colors.grey
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: provider.isLoading || _holdProcessing
                                  ? _processingLabel(fontSize: 16)
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.payment, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'PROSES PEMBAYARAN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileCartItem(
    TransactionItem item,
    TransactionProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatCurrency(item.price.toInt())} x ${item.quantity}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => provider.updateQuantity(
                          item.productId,
                          item.quantity - 1,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => provider.updateQuantity(
                          item.productId,
                          item.quantity + 1,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => provider.removeFromCart(item.productId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, _) {
        final cartItems = transactionProvider.cartItems;
        return Column(
          children: [
            // Cart header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Keranjang',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${cartItems.length} item',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Cart items with flexible height
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(child: Text('Keranjang kosong'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return _buildCartItem(item, transactionProvider);
                      },
                    ),
            ),

            // Checkout button - not in Expanded to avoid overflow
            if (cartItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total: ${_formatCurrency(transactionProvider.totalPrice.toInt())}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<TransactionProvider>(
                      builder: (context, provider, _) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (provider.isLoading || _holdProcessing)
                                ? null
                                : () => _processPayment(provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (provider.isLoading || _holdProcessing)
                                  ? Colors.grey
                                  : AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: provider.isLoading || _holdProcessing
                                ? _processingLabel(fontSize: 14)
                                : const Text('Proses Pembayaran'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCartItem(TransactionItem item, TransactionProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatCurrency(item.price.toInt())} x ${item.quantity}',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: () {
                        provider.updateQuantity(
                          item.productId,
                          item.quantity - 1,
                        );
                      },
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () {
                        provider.updateQuantity(
                          item.productId,
                          item.quantity + 1,
                        );
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  onPressed: () {
                    provider.removeFromCart(item.productId);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(
    TransactionProvider provider, {
    bool showProcessingDialog = false,
  }) async {
    _startProcessingUi();
    bool dialogShown = false;
    bool uiStopped = false;

    if (showProcessingDialog && mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Padding(
              padding: const EdgeInsets.all(16),
              child: _processingLabel(fontSize: 14),
            ),
          );
        },
      );
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final transaction = await provider.checkout(
        authProvider.user?.name ?? 'Kasir',
        context: context,
        userRole: authProvider.user?.hakAkses,
        userId: authProvider.user?.id,
      );

      if (transaction != null) {
        if (mounted) {
          await _stopProcessingUi();
          uiStopped = true;

          if (dialogShown) {
            if (mounted) {
              final nav = Navigator.of(context, rootNavigator: true);
              if (nav.canPop()) {
                nav.pop();
              }
            }
            dialogShown = false;
          }

          if (mounted) {
            _showTransactionSuccessDialog(transaction);
            // Navigate to transaction detail after dialog is closed
            // Note: Navigation happens inside the dialog
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses transaksi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (!uiStopped) {
          await _stopProcessingUi();
        }

        if (dialogShown) {
          if (mounted) {
            final nav = Navigator.of(context, rootNavigator: true);
            if (nav.canPop()) {
              nav.pop();
            }
          }
        }
      } else {
        _processingTimer?.cancel();
      }
    }
  }
}
