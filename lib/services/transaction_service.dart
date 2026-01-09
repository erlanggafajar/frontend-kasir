import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import 'api_service.dart';

class TransactionService {
  String _token = '';
  int _currentTokoId = 0;

  // Update token when user logs in
  void updateToken(String token) {
    _token = token;
  }

  // Update tokoId for data isolation
  void updateTokoId(int tokoId) {
    _currentTokoId = tokoId;
    debugPrint('TransactionService: Toko ID updated to $_currentTokoId');
  }

  // Create a new transaction
  Future<Map<String, dynamic>> createTransaction(
    Map<String, dynamic> requestBody,
  ) async {
    try {
      debugPrint('=== TRANSACTION DEBUG ===');
      debugPrint('Request body: ${requestBody.toString()}');
      debugPrint('Token available: ${_token.isNotEmpty}');
      debugPrint('Toko ID Filter: $_currentTokoId');
      debugPrint('Endpoint: /tambah-transaksi');

      // Validate tokoId is set for security
      if (_currentTokoId <= 0) {
        throw Exception(
          'Security Error: Toko ID not set. Cannot create transaction.',
        );
      }

      final response = await ApiService.post(
        '/tambah-transaksi',
        body: requestBody,
        token: _token.isNotEmpty ? _token : null,
      );

      debugPrint('API Response Status: Success');
      debugPrint('API Response: ${response.toString()}');

      // Validate response structure
      if (response.isEmpty) {
        throw Exception('Empty response from server');
      }

      // Check for error messages in response
      if (response['success'] == false || response['error'] == true) {
        final errorMessage =
            response['message'] ?? response['error'] ?? 'Transaction failed';
        throw Exception(errorMessage);
      }

      return response;
    } catch (e) {
      debugPrint('=== TRANSACTION ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error type: ${e.runtimeType}');

      // Provide more specific error messages
      if (e.toString().contains('401')) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.toString().contains('404')) {
        throw Exception(
          'Transaction endpoint not found. API may have changed.',
        );
      } else if (e.toString().contains('422')) {
        throw Exception('Invalid data format. Please check transaction data.');
      } else if (e.toString().contains('500')) {
        throw Exception('Server error. Please try again later.');
      } else if (e.toString().contains('timeout')) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else {
        throw Exception('Transaction failed: ${e.toString()}');
      }
    }
  }

  // Get transaction history
  Future<List<Transaction>> getTransactionHistory() async {
    try {
      // Validate tokoId is set for security
      if (_currentTokoId <= 0) {
        throw Exception(
          'Security Error: Toko ID not set. Cannot access transaction history.',
        );
      }

      // Use ApiService with automatic tokoId filtering
      // ApiService will automatically add toko_id filter
      final response = await ApiService.get(
        '/riwayat-transaksi?with=kasir,user',
        token: _token.isNotEmpty ? _token : null,
      );

      debugPrint('TransactionService: GET /riwayat-transaksi?with=kasir,user');
      debugPrint(
        'TransactionService: Toko ID Filter (from ApiService): $_currentTokoId',
      );
      debugPrint('Transaction History API Response: ${response.toString()}');

      dynamic data = response['data'];
      if (data is Map) {
        data =
            data['data'] ??
            data['items'] ??
            data['transaksi'] ??
            data['riwayat'] ??
            data['list'];
      }

      if (data is List) {
        final transactions = data.map((e) {
          if (e is Map<String, dynamic>) {
            return Transaction.fromJson(e);
          } else if (e is Map) {
            return Transaction.fromJson(Map<String, dynamic>.from(e));
          } else {
            throw Exception('Invalid transaction data format: $e');
          }
        }).toList();

        debugPrint('Loaded ${transactions.length} transactions');
        for (int i = 0; i < transactions.length && i < 3; i++) {
          debugPrint(
            'Transaction ${i + 1}: ID=${transactions[i].id}, Kasir="${transactions[i].namaKasir}", User ID=${transactions[i].userId}, Role=${transactions[i].userRole}',
          );
        }

        return transactions;
      }

      return [];
    } catch (e) {
      debugPrint('Error loading transaction history with enrichment: $e');
      // Fallback to basic endpoint
      try {
        // Use ApiService with automatic tokoId filtering
        final response = await ApiService.get(
          '/riwayat-transaksi',
          token: _token.isNotEmpty ? _token : null,
        );

        debugPrint('TransactionService: Fallback GET /riwayat-transaksi');
        debugPrint(
          'TransactionService: Toko ID Filter (from ApiService): $_currentTokoId',
        );
        debugPrint('Fallback API Response: ${response.toString()}');

        dynamic data = response['data'];
        if (data is Map) {
          data =
              data['data'] ??
              data['items'] ??
              data['transaksi'] ??
              data['riwayat'] ??
              data['list'];
        }

        if (data is List) {
          final transactions = data.map((e) {
            if (e is Map<String, dynamic>) {
              return Transaction.fromJson(e);
            } else if (e is Map) {
              return Transaction.fromJson(Map<String, dynamic>.from(e));
            } else {
              throw Exception('Invalid transaction data format: $e');
            }
          }).toList();

          debugPrint('Fallback loaded ${transactions.length} transactions');
          return transactions;
        }

        return [];
      } catch (fallbackError) {
        debugPrint(
          'Error loading transaction history (fallback): $fallbackError',
        );
        rethrow;
      }
    }
  }

  // Get transaction detail by ID
  Future<Transaction> getTransactionDetail(int id) async {
    try {
      // Validate tokoId is set for security
      if (_currentTokoId <= 0) {
        throw Exception(
          'Security Error: Toko ID not set. Cannot access transaction detail.',
        );
      }

      // Use ApiService with automatic tokoId filtering
      // ApiService will automatically add toko_id filter
      final response = await ApiService.get(
        '/detail-transaksi/$id?with=kasir,user',
        token: _token.isNotEmpty ? _token : null,
      );

      debugPrint(
        'TransactionService: GET /detail-transaksi/$id?with=kasir,user',
      );
      debugPrint(
        'TransactionService: Toko ID Filter (from ApiService): $_currentTokoId',
      );
      debugPrint('Trying enriched endpoint for transaction $id');

      debugPrint('API Response for detail $id: ${response.toString()}');

      dynamic data = response['data'];
      if (data is Map) {
        data = data['data'] ?? data['transaksi'] ?? data['detail'] ?? data;
      }

      if (data is Map) {
        debugPrint('Parsed data for detail $id: ${data.toString()}');
        final transaction = Transaction.fromJson(
          Map<String, dynamic>.from(data),
        );

        debugPrint(
          'Transaction Detail: ID=${transaction.id}, Kasir="${transaction.namaKasir}", User ID=${transaction.userId}, Role=${transaction.userRole}',
        );

        return transaction;
      }

      return Transaction.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Error loading transaction detail with enrichment: $e');
      // Fallback to basic endpoint
      try {
        // Use ApiService with automatic tokoId filtering
        final response = await ApiService.get(
          '/detail-transaksi/$id',
          token: _token.isNotEmpty ? _token : null,
        );

        debugPrint('TransactionService: Fallback GET /detail-transaksi/$id');
        debugPrint(
          'TransactionService: Toko ID Filter (from ApiService): $_currentTokoId',
        );
        debugPrint('Trying basic endpoint for transaction $id');

        debugPrint('Basic API Response for detail $id: ${response.toString()}');

        dynamic data = response['data'];
        if (data is Map) {
          data = data['data'] ?? data['transaksi'] ?? data['detail'] ?? data;
        }

        if (data is Map) {
          debugPrint('Basic parsed data for detail $id: ${data.toString()}');
          final transaction = Transaction.fromJson(
            Map<String, dynamic>.from(data),
          );

          debugPrint(
            'Basic Transaction Detail: ID=${transaction.id}, Kasir="${transaction.namaKasir}", User ID=${transaction.userId}, Role=${transaction.userRole}',
          );

          return transaction;
        }

        return Transaction.fromJson(Map<String, dynamic>.from(response));
      } catch (fallbackError) {
        debugPrint(
          'Error loading transaction detail (fallback): $fallbackError',
        );
        rethrow;
      }
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(int transactionId) async {
    try {
      // Validate tokoId is set for security
      if (_currentTokoId <= 0) {
        throw Exception(
          'Security Error: Toko ID not set. Cannot delete transaction.',
        );
      }

      await ApiService.delete(
        '/transaksi/$transactionId',
        token: _token.isNotEmpty ? _token : null,
      );

      debugPrint('Transaction $transactionId deleted successfully');
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  // Export transaction to Excel
  Future<http.Response> exportToExcel(String date) async {
    // This would need to be implemented in ApiService if needed
    throw UnimplementedError('Export to Excel not implemented');
  }

  // Download PDF
  Future<http.Response> downloadPdf(String date) async {
    // This would need to be implemented in ApiService if needed
    throw UnimplementedError('Download PDF not implemented');
  }
}
