import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/app_scaffold.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../styles/color_style.dart';
import '../../models/product_model.dart';
import '../qr/qr_scanner_screen.dart'; // Import scanner

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _kode = TextEditingController();
  final _nama = TextEditingController();
  final _harga = TextEditingController();
  final _stok = TextEditingController();

  bool _isLoading = false;
  bool get isEdit => widget.product != null;

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
    if (isEdit) {
      _kode.text = widget.product!.kodeBarang;
      _nama.text = widget.product!.nama;
      _harga.text = widget.product!.harga.toString();
      _stok.text = widget.product!.stok.toString();
    }
  }

  // Fitur Scan untuk mengisi Kode Barang otomatis
  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _kode.text = result;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kode berhasil di-scan!')));
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
      showBottomNav: false,
      currentIndex: 1,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Field Kode Barang dengan Tombol Scan
              _field(
                _kode,
                'Kode Barang / Barcode',
                icon: Icons.qr_code_scanner,
                suffix: IconButton(
                  icon: const Icon(Icons.camera_alt, color: AppColors.primary),
                  onPressed: _scanBarcode,
                ),
              ),
              _field(_nama, 'Nama Produk', icon: Icons.inventory_2),
              _priceField(_harga),
              _field(_stok, 'Stok Awal', number: true, icon: Icons.storage),

              const SizedBox(height: 40),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEdit ? 'SIMPAN PERUBAHAN' : 'TAMBAH PRODUK',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final harga = int.tryParse(_harga.text) ?? 0;
    final stok = int.tryParse(_stok.text) ?? 0;

    // Validasi tambahan untuk memastikan tidak ada nilai negatif
    if (harga < 0 || stok < 0) {
      _showSnack('Harga dan stok tidak boleh negatif', isError: true);
      return;
    }

    final provider = context.read<ProductProvider>();
    final token = context.read<AuthProvider>().token!;

    setState(() => _isLoading = true);

    try {
      if (isEdit) {
        await provider.updateProduct(
          id: widget.product!.id,
          kodeBarang: _kode.text,
          nama: _nama.text,
          harga: harga,
          stok: stok,
          token: token,
        );
        _showSnack('Produk berhasil diperbarui');
      } else {
        await provider.createProduct(
          kodeBarang: _kode.text,
          nama: _nama.text,
          harga: harga,
          stok: stok,
          token: token,
        );
        _showSnack('Produk berhasil ditambahkan');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception:', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool number = false,
    IconData? icon,
    Widget? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              )
            : TextInputType.text,
        inputFormatters: number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        validator: (v) {
          if (v == null || v.isEmpty) {
            return 'Data ini tidak boleh kosong';
          }

          // Validasi untuk field angka (harga dan stok)
          if (number) {
            final value = int.tryParse(v);
            if (value == null) {
              return 'Masukkan angka yang valid';
            }
            if (value < 0) {
              return 'Tidak boleh kurang dari 0';
            }

            // Validasi tambahan untuk harga
            if (label.toLowerCase().contains('harga') && value < 100) {
              return 'Harga minimal 100';
            }

            // Validasi tambahan untuk stok
            if (label.toLowerCase().contains('stok') && value < 0) {
              return 'Stok tidak boleh negatif';
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 22) : null,
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _priceField(TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: false,
          signed: false,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          if (v == null || v.isEmpty) {
            return 'Data ini tidak boleh kosong';
          }
          final value = int.tryParse(v);
          if (value == null) {
            return 'Masukkan angka yang valid';
          }
          if (value < 0) {
            return 'Tidak boleh kurang dari 0';
          }
          if (value < 100) {
            return 'Harga minimal 100';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Harga Jual',
          hintText: 'Masukkan harga jual',
          prefixIcon: const Icon(Icons.payments),
          suffixText: controller.text.isNotEmpty
              ? _formatCurrency(int.tryParse(controller.text) ?? 0)
              : 'Rp0',
          suffixStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {}); // Rebuild to update suffix text
        },
      ),
    );
  }
}
