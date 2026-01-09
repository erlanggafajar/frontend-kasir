import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/transaction_model.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../services/wifi_service.dart';
import '../../../styles/color_style.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/pdf_receipt_service.dart';
import '../../../services/user_service.dart';

class TransactionDetailScreen extends StatefulWidget {
  final int? transactionId;
  final Transaction? transaction;
  final int displayNumber;

  const TransactionDetailScreen({
    super.key,
    this.transactionId,
    this.transaction,
    required this.displayNumber,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Transaction? _transaction;
  bool _isLoading = true;

  // Cache for user names to avoid repeated API calls
  final Map<int, String> _userNameCache = {};

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    if (widget.transaction != null &&
        widget.transaction!.namaKasir.trim().isNotEmpty) {
      // Use provided transaction if it has complete data
      setState(() {
        _transaction = widget.transaction;
        _isLoading = false;
      });
    } else if (widget.transactionId != null) {
      // Load fresh data from API
      try {
        final provider = context.read<TransactionProvider>();
        final transaction = await provider.service.getTransactionDetail(
          widget.transactionId!,
        );
        setState(() {
          _transaction = transaction;
          _isLoading = false;
        });
      } catch (e) {
        // Fallback to provided transaction if available
        setState(() {
          _transaction = widget.transaction;
          _isLoading = false;
        });
      }
    } else {
      // Fallback to provided transaction
      setState(() {
        _transaction = widget.transaction;
        _isLoading = false;
      });
    }
  }

  String _generateTransactionNumber() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 10000000000;
    return '#${random.toString().padLeft(10, '0')}';
  }

  String _formatCurrency(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      // Convert to UTC+7 (WIB) if the date is in UTC
      final wibDate = date.isUtc ? date.toLocal() : date;
      return DateFormat('dd MMMM yyyy, HH:mm').format(wibDate);
    } catch (e) {
      return dateString;
    }
  }

  Future<String> _getUserNameById(int userId) async {
    // Check cache first
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token;

      final userName = await UserService.getUserNameById(userId, token: token);

      if (userName != null) {
        // Cache the result
        _userNameCache[userId] = userName;
        return userName;
      }
    } catch (e) {
      print('Error fetching user name for user ID $userId: $e');
    }

    // Return fallback to existing namaKasir if available
    if (_transaction != null && _transaction!.namaKasir.trim().isNotEmpty) {
      return _transaction!.namaKasir;
    }

    return 'Tidak diketahui';
  }

  Future<void> _printReceipt() async {
    if (_transaction == null) return;

    // Show loading dialog with animated progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated loading icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: Icon(
                      Icons.picture_as_pdf,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Progress bar
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Container(
                    width: 200,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Loading text with animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: const Text(
                      'Mempersiapkan struk PDF...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Subtitle with fade-in animation
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value * 0.7,
                    child: const Text(
                      'Mohon tunggu sebentar...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await PdfReceiptService.openInExternalApp(
        _transaction!,
        widget.displayNumber,
        context: context,
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog
      if (context.mounted) {
        // Add small delay for smoother transition
        await Future.delayed(const Duration(milliseconds: 300));

        showDialog(
          context: context,
          builder: (context) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: AlertDialog(
                    icon: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    title: const Text('Struk Berhasil Dibuka!'),
                    content: const Text(
                      'Struk PDF telah tersimpan di penyimpanan eksternal.',
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          // Add smooth exit animation
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'OK',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error dialog
      if (context.mounted) {
        // Add small delay for smoother transition
        await Future.delayed(const Duration(milliseconds: 300));

        showDialog(
          context: context,
          builder: (context) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: AlertDialog(
                    icon: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    title: const Text('Gagal Membuka Struk'),
                    content: Text(
                      'Terjadi kesalahan saat membuka struk PDF: ${e.toString()}',
                      textAlign: TextAlign.center,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          // Add smooth exit animation
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Tutup',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
    }
  }

  Future<void> _printDirectly() async {
    if (_transaction == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mempersiapkan printer...'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );

      await PdfReceiptService.printDirectly(
        _transaction!,
        widget.displayNumber,
        context: context,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencetak struk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (_isLoading) {
      return AppScaffold(
        title: 'Detail Transaksi',
        currentIndex: 2,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_transaction == null) {
      return AppScaffold(
        title: 'Detail Transaksi',
        currentIndex: 2,
        body: const Center(child: Text('Transaksi tidak ditemukan')),
      );
    }

    // Cek hak akses
    debugPrint('=== DETAIL TRANSACTION ACCESS CHECK ===');
    debugPrint('User role: ${authProvider.userRole}');
    debugPrint('User ID: ${authProvider.userId}');
    debugPrint('Transaction userId: ${_transaction!.userId}');
    debugPrint('Transaction namaKasir: ${_transaction!.namaKasir}');
    debugPrint(
      'Can access: ${authProvider.canAccessTransactionDetail(_transaction!.userId ?? 0, transactionKasirName: _transaction!.namaKasir)}',
    );

    final canAccess = authProvider.canAccessTransactionDetail(
      _transaction!.userId ?? 0,
      transactionKasirName: _transaction!.namaKasir,
    );

    if (!canAccess) {
      debugPrint('ACCESS DENIED - Showing lock screen');
      return AppScaffold(
        title: 'Detail Transaksi',
        currentIndex: 2,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Anda tidak memiliki akses ke transaksi ini',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                'Hanya admin dan kasir yang membuat transaksi ini yang dapat melihat detailnya',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      debugPrint('ACCESS GRANTED - Showing transaction detail');
    }

    return AppScaffold(
      title: 'Detail Transaksi',
      currentIndex: 2,
      body: Column(
        children: [
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction header
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaksi #${widget.displayNumber}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (_transaction != null)
                              Text(
                                'No.Transaksi: ${_generateTransactionNumber()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Tanggal: ${_formatDate(_transaction!.tanggal)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            FutureBuilder<String>(
                              future: _getUserNameById(
                                _transaction!.userId ?? 0,
                              ),
                              builder: (context, snapshot) {
                                String displayName = 'Tidak diketahui';

                                if (snapshot.hasData) {
                                  displayName = snapshot.data!;
                                } else if (snapshot.hasError) {
                                  // Fallback to existing namaKasir when API fails
                                  if (_transaction!.namaKasir
                                      .trim()
                                      .isNotEmpty) {
                                    displayName = _transaction!.namaKasir;
                                  } else {
                                    displayName = 'Error loading';
                                  }
                                } else if (_transaction!.namaKasir
                                    .trim()
                                    .isNotEmpty) {
                                  // Show existing namaKasir while loading
                                  displayName = _transaction!.namaKasir;
                                }

                                return Text(
                                  'Kasir: $displayName',
                                  style: const TextStyle(color: Colors.grey),
                                );
                              },
                            ),
                            const SizedBox(height: 12),

                            // WiFi Information Card - only show if store has WiFi
                            FutureBuilder<bool>(
                              future: WiFiService.hasWiFiSettings(),
                              builder: (context, hasWifiSnapshot) {
                                if (hasWifiSnapshot.data == true) {
                                  return FutureBuilder<Map<String, String>>(
                                    future: WiFiService.getWiFiSettings(),
                                    builder: (context, snapshot) {
                                      final wifiName =
                                          snapshot.data?['name'] ??
                                          'Kasir-WiFi';
                                      final wifiPassword =
                                          snapshot.data?['password'] ??
                                          'Kasir123456';

                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.wifi,
                                                  color: AppColors.primary,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                const Text(
                                                  'Info WiFi',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const Spacer(),
                                                GestureDetector(
                                                  onTap: () {
                                                    final wifiInfo =
                                                        'WiFi: $wifiName\nPassword: $wifiPassword';
                                                    // Copy to clipboard (simplified version)
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'WiFi: $wifiName\nPassword: $wifiPassword',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                        duration:
                                                            const Duration(
                                                              seconds: 3,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Icon(
                                                    Icons.copy,
                                                    size: 14,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Network: ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    wifiName,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Password: ',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    wifiPassword,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                } else {
                                  // Don't show anything if store doesn't have WiFi
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Items list
                  Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Item Pembelian',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[300]),
                        ..._transaction!.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.namaProduk,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${_formatCurrency(item.harga)} x ${item.quantity}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatCurrency(item.quantity * item.harga),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.grey[300]),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pembayaran',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatCurrency(_transaction!.totalHarga),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF106E49),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Column(
                    children: [
                      // Primary action - Open in external app
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _printReceipt,
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text(
                            'Buka Struk PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Secondary action - Cetak Langsung
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _printDirectly,
                          icon: const Icon(Icons.print, size: 16),
                          label: const Text(
                            'Cetak Langsung',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            side: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Extra padding at bottom
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
