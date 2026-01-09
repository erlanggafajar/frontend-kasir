import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../styles/color_style.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  bool _isLoading = false;

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  void _loadProductDetail() {
    final token = context.read<AuthProvider>().token!;
    final provider = context.read<ProductProvider>();

    setState(() {
      _isLoading = true;
    });

    provider
        .getProductDetail(widget.productId, token)
        .then((product) {
          if (mounted) {
            setState(() {
              _product = product;
              _isLoading = false;
            });
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal memuat detail: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detail Produk',
      showBottomNav: false,
      currentIndex: 1,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? const Center(child: Text('Data tidak ditemukan'))
          : Consumer<ProductProvider>(
              builder: (context, provider, _) {
                // Sinkronisasi data jika ada perubahan di provider (misal setelah edit)
                final updatedProduct = provider.products.firstWhere(
                  (p) => p.id == widget.productId,
                  orElse: () => _product!,
                );

                _product = updatedProduct;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // AREA QR CODE OTOMATIS
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              QrImageView(
                                data: _product!.kodeBarang,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _product!.kodeBarang,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // INFO DETAIL PRODUK
                      _item('Nama Produk', _product!.nama, Icons.inventory),
                      _item(
                        'Harga Jual',
                        _formatCurrency(_product!.harga),
                        Icons.payments,
                      ),
                      _item(
                        'Stok Tersedia',
                        _product!.stok.toString(),
                        Icons.layers,
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _item(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 20, thickness: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
