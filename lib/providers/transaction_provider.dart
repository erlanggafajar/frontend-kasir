// lib/providers/transaction_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'auth_provider.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();
  String _token = '';

  bool _isLoading = false;
  List<Transaction> _transactions = [];
  final List<TransactionItem> _cartItems = [];

  // Store current tokoId for data isolation
  int _currentTokoId = 0;

  TransactionProvider();

  // Helper method to get fallback cashier name
  String _getFallbackKasirName(BuildContext? context) {
    debugPrint('=== DEBUG: _getFallbackKasirName called ===');

    if (context == null) {
      debugPrint('Context is null for fallback cashier name');
      return 'Kasir Tidak Diketahui';
    }

    try {
      // Check if AuthProvider is available using safe access
      AuthProvider? authProvider;
      try {
        authProvider = context.read<AuthProvider>();
        debugPrint('AuthProvider found successfully');
      } catch (e) {
        debugPrint('AuthProvider not found in context: $e');
        return 'Kasir Tidak Diketahui';
      }

      debugPrint('AuthProvider user: ${authProvider.user}');
      debugPrint('AuthProvider user name: "${authProvider.user?.name}"');
      debugPrint('AuthProvider userName getter: "${authProvider.userName}"');

      // Check if user data exists and name is not empty
      if (authProvider.user != null &&
          authProvider.user!.name.isNotEmpty &&
          authProvider.user!.name.trim().isNotEmpty) {
        debugPrint('Using user name as fallback: "${authProvider.user!.name}"');
        return authProvider.user!.name;
      } else {
        debugPrint(
          'User data is null or name is empty, using userName getter: "${authProvider.userName}"',
        );
        if (authProvider.userName.isNotEmpty &&
            authProvider.userName != 'Unknown User') {
          return authProvider.userName;
        }
        debugPrint('userName getter also empty, returning default');
        return 'Kasir Tidak Diketahui';
      }
    } catch (e) {
      debugPrint('Error getting user for fallback: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return 'Kasir Tidak Diketahui';
    }
  }

  bool get isLoading => _isLoading;
  List<Transaction> get transactions => _transactions;
  List<TransactionItem> get cartItems => _cartItems;
  TransactionService get service => _service;

  // Update token when user logs in
  void updateToken(String newToken) {
    _token = newToken;
    _service.updateToken(newToken);
    debugPrint('TransactionProvider token updated');
  }

  // Update tokoId for data isolation
  void updateTokoId(int tokoId) {
    _currentTokoId = tokoId;
    _service.updateTokoId(tokoId);
    debugPrint('TransactionProvider: Toko ID updated to $_currentTokoId');

    // Clear existing transactions to prevent data leakage
    _transactions.clear();
    notifyListeners();
    debugPrint(
      'TransactionProvider: Cleared existing transactions for security',
    );
  }

  double get totalPrice {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  // Cart operations
  void addToCart(TransactionItem item) {
    final existingIndex = _cartItems.indexWhere(
      (cartItem) => cartItem.productId == item.productId,
    );

    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity += item.quantity;
      _cartItems[existingIndex].subtotal =
          (_cartItems[existingIndex].price * _cartItems[existingIndex].quantity)
              .toInt();
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _cartItems[index].quantity = newQuantity;
      _cartItems[index].subtotal = (newQuantity * _cartItems[index].price)
          .toInt();
      notifyListeners();
    }
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Transaction operations
  Future<void> loadTransactions({
    int maxRetries = 3,
    BuildContext? context,
  }) async {
    debugPrint('=== DEBUG: loadTransactions called ===');
    _isLoading = true;
    notifyListeners();

    // Store context reference to avoid async gaps
    BuildContext? safeContext = context;

    // Get current user info for filtering
    int? currentUserId;
    String? currentUserRole;

    if (safeContext != null) {
      try {
        final authProvider = safeContext.read<AuthProvider>();
        currentUserId = authProvider.userId;
        currentUserRole = authProvider.userRole;
        debugPrint('Current user: ID=$currentUserId, Role=$currentUserRole');
      } catch (e) {
        debugPrint('Error getting auth provider: $e');
      }
    }

    int retryCount = 0;
    Exception? lastException;

    while (retryCount < maxRetries) {
      try {
        final history = await _service.getTransactionHistory();

        debugPrint('Loaded ${history.length} transactions from API');
        for (int i = 0; i < history.length && i < 3; i++) {
          debugPrint(
            'Transaction ${i + 1}: ID=${history[i].id}, Kasir="${history[i].namaKasir}", Total=${history[i].totalHarga}, Items=${history[i].items.length}',
          );
        }

        // Apply fallback for missing kasir names BEFORE filtering (but don't override existing names)
        final enrichedHistory = history.map((transaction) {
          if (transaction.namaKasir.trim().isEmpty) {
            debugPrint(
              '⚠️ Transaction ${transaction.id} has empty kasir name, keeping as empty',
            );
            return transaction; // Keep empty, don't override with current user
          }
          return transaction;
        }).toList();

        debugPrint(
          'After fallback enrichment: ${enrichedHistory.length} transactions',
        );
        for (int i = 0; i < enrichedHistory.length && i < 3; i++) {
          debugPrint(
            'Enriched Transaction ${i + 1}: ID=${enrichedHistory[i].id}, Kasir="${enrichedHistory[i].namaKasir}", User ID=${enrichedHistory[i].userId}, Role=${enrichedHistory[i].userRole}',
          );
        }

        debugPrint('=== DEBUG: Starting Transaction Filtering ===');
        debugPrint('Current User: ID=$currentUserId, Role=$currentUserRole');
        debugPrint(
          'Auth Provider User ID: ${safeContext?.read<AuthProvider>().userId}',
        );
        debugPrint(
          'Auth Provider User Name: ${safeContext?.read<AuthProvider>().userName}',
        );
        debugPrint(
          'Total transactions before filtering: ${enrichedHistory.length}',
        );

        for (int i = 0; i < enrichedHistory.length && i < 5; i++) {
          final t = enrichedHistory[i];
          debugPrint(
            'Transaction ${i + 1}: ID=${t.id}, userId=${t.userId}, kasir="${t.namaKasir}"',
          );
        }

        // IMPORTANT: Always filter for KASIR role to prevent data leakage
        List<Transaction> filteredHistory = enrichedHistory;
        if (currentUserRole == 'KASIR' && currentUserId != null) {
          // Get current user info for comparison
          String? currentUserName;
          int? currentUserTokoId;
          if (safeContext != null) {
            try {
              final auth = safeContext.read<AuthProvider>();
              currentUserName = auth.userName;
              currentUserTokoId = auth.tokoId;
            } catch (e) {
              debugPrint('Error getting auth provider for KASIR filtering: $e');
            }
          }

          debugPrint('=== KASIR FILTERING ENABLED ===');
          debugPrint(
            'Current KASIR: ID=$currentUserId, Name="$currentUserName", Toko=$currentUserTokoId',
          );

          filteredHistory = enrichedHistory.where((transaction) {
            // KASIR hanya lihat transaksi yang dibuat oleh dirinya sendiri
            if (transaction.userId == currentUserId) {
              debugPrint(
                ' KASIR FILTER: Transaction ${transaction.id} ALLOWED - userId match (${transaction.userId} == $currentUserId)',
              );
              return true;
            }

            debugPrint(
              ' KASIR FILTER: Transaction ${transaction.id} DENIED - not owned by user (${transaction.userId} != $currentUserId)',
            );
            return false;
          }).toList();
          debugPrint(
            ' KASIR FILTER RESULT: ${filteredHistory.length}/${enrichedHistory.length} transactions remain',
          );
        } else if (currentUserRole == 'ADMIN') {
          debugPrint(
            '👑 ADMIN: showing all transactions from toko for enrichment',
          );
          // ADMIN should see all transactions from their toko
          if (safeContext != null) {
            try {
              final auth = safeContext.read<AuthProvider>();
              final adminTokoId = auth.tokoId;
              if (adminTokoId != null) {
                filteredHistory = enrichedHistory
                    .where((t) => t.tokoId == adminTokoId)
                    .toList();
                debugPrint(
                  ' ADMIN FILTER: ${filteredHistory.length}/${enrichedHistory.length} transactions from toko $adminTokoId',
                );
              }
            } catch (e) {
              debugPrint('Error getting admin toko_id: $e');
            }
          }
        } else {
          debugPrint(
            '⚠️ Unknown role: $currentUserRole - applying safety filter',
          );
          filteredHistory = []; // Safety: show nothing for unknown roles
        }

        // Some APIs return only transaction IDs on history.
        // If critical fields are missing, enrich each entry from detail endpoint.
        final bool shouldEnrich = filteredHistory.any(
          (t) =>
              t.totalHarga <= 0 ||
              t.items.isEmpty ||
              t.namaKasir.trim().isEmpty,
        );

        debugPrint('🔍 Should enrich: $shouldEnrich');
        debugPrint('📊 Filtered transactions count: ${filteredHistory.length}');

        if (!shouldEnrich) {
          debugPrint('✅ No enrichment needed - using filtered data as-is');
          _transactions = filteredHistory;
          _isLoading = false;
          notifyListeners();
          return;
        }

        debugPrint('🔄 Starting enrichment process...');
        final List<Transaction> enriched = [];

        // ONLY enrich transactions that passed the filter
        for (final t in filteredHistory) {
          try {
            if (t.id > 0) {
              debugPrint(
                '🔍 Fetching detail for ALLOWED transaction ID: ${t.id}',
              );
              final detail = await _service.getTransactionDetail(t.id);
              debugPrint(
                '✅ Detail result: ID=${detail.id}, Kasir="${detail.namaKasir}", Total=${detail.totalHarga}, Items=${detail.items.length}',
              );

              // Don't override kasir name - keep original from API
              if (detail.namaKasir.trim().isEmpty) {
                debugPrint(
                  '⚠️ Transaction ${detail.id} has empty kasir name, keeping as empty',
                );
                // Don't override with current user name
                enriched.add(detail);
              } else {
                enriched.add(detail);
              }
            } else {
              enriched.add(t);
            }
          } catch (e) {
            // Fallback to history item if detail fails - don't override kasir name
            debugPrint('❌ Error loading detail for transaction ${t.id}: $e');
            // Keep original transaction data without modifying kasir name
            enriched.add(t);
          }
        }

        _transactions = enriched;
        debugPrint('After enrichment: ${enriched.length} transactions');
        for (int i = 0; i < enriched.length && i < 3; i++) {
          debugPrint(
            'Enriched Transaction ${i + 1}: ID=${enriched[i].id}, Kasir="${enriched[i].namaKasir}", Total=${enriched[i].totalHarga}, Items=${enriched[i].items.length}',
          );
        }

        // FINAL SAFETY CHECK: Ensure no data leakage for KASIR role
        if (currentUserRole == 'KASIR' && currentUserId != null) {
          final beforeSafetyCheck = enriched.length;
          final finalTransactions = enriched.where((transaction) {
            final isAllowed = transaction.userId == currentUserId;
            if (!isAllowed) {
              debugPrint(
                '🚨 SAFETY CHECK: Removing transaction ${transaction.id} - userId=${transaction.userId} != $currentUserId',
              );
            }
            return isAllowed;
          }).toList();

          if (finalTransactions.length != beforeSafetyCheck) {
            debugPrint(
              '🔒 SAFETY FILTER APPLIED: $beforeSafetyCheck -> ${finalTransactions.length} transactions',
            );
            _transactions = finalTransactions;
          } else {
            debugPrint(
              '✅ SAFETY CHECK PASSED: All transactions belong to current user',
            );
          }
        }
        _isLoading = false;
        notifyListeners();
        return;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        retryCount++;
        debugPrint(
          'Error loading transactions (attempt $retryCount/$maxRetries): $e',
        );

        if (retryCount < maxRetries) {
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(milliseconds: 1000 * retryCount));
        }
      }
    }

    // All retries failed
    debugPrint(
      'Failed to load transactions after $maxRetries attempts: $lastException',
    );
    _transactions = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<Transaction?> checkout(
    String cashierName, {
    BuildContext? context,
    String? userRole,
    int? userId,
  }) async {
    // Store context reference before async operations
    final checkoutContext = context;

    if (_cartItems.isEmpty) {
      if (checkoutContext != null) {
        ScaffoldMessenger.of(checkoutContext).showSnackBar(
          const SnackBar(
            content: Text('Keranjang masih kosong'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    // Check if token is available
    if (_token.isEmpty) {
      if (checkoutContext != null) {
        ScaffoldMessenger.of(checkoutContext).showSnackBar(
          const SnackBar(
            content: Text('Silakan login terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Create items data for API - try multiple formats
      final itemsData = _cartItems
          .map((item) => {'id_barang': item.idBarang, 'qty': item.qty})
          .toList();

      debugPrint('=== CHECKOUT DEBUG ===');
      debugPrint('Token available: ${_token.isNotEmpty}');
      debugPrint('Cart items: ${_cartItems.length}');
      debugPrint('User ID: $userId, Role: $userRole, Cashier: $cashierName');

      // Validate all products exist before creating transaction
      debugPrint('=== VALIDATING PRODUCTS ===');
      for (final item in _cartItems) {
        debugPrint(
          'Validating product ID: ${item.idBarang} - ${item.namaBarang}',
        );
        // Note: You might want to add product validation here if needed
        if (item.idBarang <= 0) {
          throw Exception(
            'Invalid product ID: ${item.idBarang} for ${item.namaBarang}',
          );
        }
      }

      // Try the current format first (since we know it works)
      final requestBody = <String, dynamic>{
        'data': itemsData,
        if (userId != null) 'user_id': userId,
        if (userRole != null) 'user_role': userRole,
        'nama_kasir': cashierName,
      };

      debugPrint('=== SENDING TRANSACTION ===');
      debugPrint('Request body: ${requestBody.toString()}');

      final response = await _service.createTransaction(requestBody);
      debugPrint('✅ Transaction successful!');

      // Check if response indicates success
      if (response['success'] == false ||
          response['message'] != null &&
              response['message'].toString().toLowerCase().contains('error')) {
        throw Exception(response['message'] ?? 'Transaction failed');
      }

      // Create local transaction object
      final transaction = Transaction(
        id:
            response['id'] ??
            response['data']?['id'] ??
            DateTime.now().millisecondsSinceEpoch,
        tanggal:
            response['tanggal'] ??
            response['data']?['tanggal'] ??
            DateTime.now().toIso8601String(),
        namaKasir:
            response['nama_kasir'] ??
            response['data']?['nama_kasir'] ??
            cashierName,
        userRole: userRole,
        userId: userId, // Tambahkan userId
        items: List.from(_cartItems),
        totalHarga:
            response['total_harga'] ??
            response['data']?['total_harga'] ??
            totalPrice.toInt(),
      );

      // Debug logging untuk tracking
      debugPrint('Transaction created with userId: ${transaction.userId}');
      debugPrint('Transaction userRole: ${transaction.userRole}');
      debugPrint('Transaction namaKasir: ${transaction.namaKasir}');

      // Add to local list
      _transactions.insert(0, transaction);

      // Clear cart
      clearCart();

      return transaction;
    } catch (e) {
      debugPrint('Error during checkout: $e');
      debugPrint('Error type: ${e.runtimeType}');

      // Handle authentication error
      if (checkoutContext != null) {
        final authProvider = checkoutContext.read<AuthProvider>();
        authProvider.handleAuthError(e.toString());

        String errorMessage = 'Gagal memproses transaksi';

        // Provide more specific error messages
        if (e.toString().toLowerCase().contains('401')) {
          errorMessage = 'Sesi login habis. Silakan login kembali.';
        } else if (e.toString().toLowerCase().contains('tidak ditemukan')) {
          errorMessage =
              'Produk tidak ditemukan di database. Silakan refresh produk atau hapus dari keranjang.';
        } else if (e.toString().toLowerCase().contains('timeout')) {
          errorMessage = 'Server terlalu lama merespons. Coba lagi.';
        } else if (e.toString().toLowerCase().contains('server')) {
          errorMessage = 'Server sedang bermasalah. Coba lagi nanti.';
        } else {
          errorMessage = 'Gagal memproses transaksi: ${e.toString()}';
        }

        ScaffoldMessenger.of(checkoutContext).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ULANGI',
              onPressed: () => checkout(cashierName, context: checkoutContext),
            ),
          ),
        );
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete transaction
  Future<void> deleteTransaction(
    int transactionId, {
    BuildContext? context,
  }) async {
    debugPrint('=== DELETE TRANSACTION DEBUG ===');
    debugPrint('Deleting transaction ID: $transactionId');

    // Store context reference before async operations
    final deleteContext = context;

    try {
      await _service.deleteTransaction(transactionId);
      _transactions.removeWhere((t) => t.id == transactionId);
      notifyListeners();

      debugPrint('Transaction $transactionId removed from local list');

      // Show success message if context is available
      if (deleteContext != null) {
        ScaffoldMessenger.of(deleteContext).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting transaction: $e');

      // Show error message if context is available
      if (deleteContext != null) {
        String errorMessage = 'Gagal menghapus transaksi';

        // Provide more specific error messages
        if (e.toString().contains('hak akses tidak sesuai')) {
          errorMessage =
              'Anda tidak memiliki izin untuk menghapus transaksi ini.';
        } else if (e.toString().contains('Koneksi ke server terputus')) {
          errorMessage =
              'Koneksi terputus. Pastikan koneksi internet stabil dan coba lagi.';
        } else if (e.toString().contains('Server terlalu lama merespons')) {
          errorMessage =
              'Server sedang sibuk. Silakan coba lagi dalam beberapa saat.';
        } else if (e.toString().contains('Tidak dapat terhubung ke server')) {
          errorMessage =
              'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
        } else if (e.toString().toLowerCase().contains('unauthorized') ||
            e.toString().toLowerCase().contains('401')) {
          errorMessage = 'Sesi login habis. Silakan login kembali.';
        } else if (e.toString().toLowerCase().contains('404')) {
          errorMessage = 'Transaksi tidak ditemukan atau sudah dihapus.';
        } else if (e.toString().toLowerCase().contains('403')) {
          errorMessage =
              'Anda tidak memiliki izin untuk menghapus transaksi ini.';
        } else if (e.toString().toLowerCase().contains('500')) {
          errorMessage = 'Terjadi kesalahan pada server. Silakan coba lagi.';
        } else {
          errorMessage = 'Gagal menghapus transaksi: ${e.toString()}';
        }

        ScaffoldMessenger.of(deleteContext).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ULANGI',
              onPressed: () =>
                  deleteTransaction(transactionId, context: deleteContext),
            ),
          ),
        );
      }
      rethrow;
    }
  }

  // Export functions
  Future<void> exportToExcel(DateTime date) async {
    try {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _service.exportToExcel(dateString);
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      rethrow;
    }
  }

  Future<void> downloadPdf(DateTime date) async {
    try {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await _service.downloadPdf(dateString);
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      rethrow;
    }
  }
}
