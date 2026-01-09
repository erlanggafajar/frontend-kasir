import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class ProductService {
  static const String _baseUrl = 'https://kasir.tgh.my.id/api/produk';

  // Store current tokoId for data isolation
  int _currentTokoId = 0;

  // Update tokoId for data filtering
  void updateTokoId(int tokoId) {
    _currentTokoId = tokoId;
    debugPrint('ProductService: Toko ID updated to $_currentTokoId');
  }

  // Helper untuk header agar konsisten di semua request
  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'Authorization': 'Bearer $token',
  };

  // ======================
  // GET LIST PRODUK (WITH PAGINATION)
  // ======================
  Future<List<ProductModel>> getProducts({
    required String token,
    int page = 1,
    int limit = 5,
    String search = '',
  }) async {
    try {
      // Build URL with pagination and tokoId filter
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (search.isNotEmpty) 'search': search,
          if (_currentTokoId > 0) 'toko_id': _currentTokoId.toString(),
        },
      );

      debugPrint('ProductService: GET $uri');
      debugPrint('ProductService: Toko ID Filter: $_currentTokoId');

      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        throw Exception('Sesi berakhir, silakan login ulang');
      }
      if (response.statusCode != 200) {
        throw Exception('Gagal memuat produk (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> listData = [];

      if (decoded is List) {
        listData = decoded;
      } else if (decoded is Map) {
        listData = decoded['data'] ?? decoded['produk'] ?? [];
      }

      return listData
          .map((item) => ProductModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Service Error [getProducts]: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<List<ProductModel>> getAllProducts(String token) async {
    return await getProducts(token: token, page: 1, limit: 1000);
  }

  // ======================
  // CREATE PRODUK
  // ======================
  Future<void> createProduct({
    required String kodeBarang,
    required String nama,
    required int harga,
    required int stok,
    required String token,
  }) async {
    try {
      final requestBody = {
        'kode_barang': kodeBarang,
        'nama': nama,
        'harga': harga,
        'stok': stok,
        if (_currentTokoId > 0) 'toko_id': _currentTokoId,
      };

      debugPrint('ProductService: POST $_baseUrl');
      debugPrint('ProductService: Toko ID Filter: $_currentTokoId');
      debugPrint('ProductService: Request Body: $requestBody');

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers(token),
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        throw Exception('Sesi berakhir, silakan login ulang');
      }

      if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['message'] ?? 'Kode barang sudah ada atau data tidak valid',
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal menambah produk: ${response.body}');
      }
    } catch (e) {
      debugPrint('Service Error [createProduct]: $e');
      rethrow;
    }
  }

  // ======================
  // UPDATE PRODUK
  // ======================
  Future<void> updateProduct({
    required int id,
    required String kodeBarang,
    required String nama,
    required int harga,
    required int stok,
    required String token,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/$id'),
            headers: _headers(token),
            body: jsonEncode({
              'kode_barang': kodeBarang,
              'nama': nama,
              'harga': harga,
              'stok': stok,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        throw Exception('Sesi berakhir, silakan login ulang');
      }
      if (response.statusCode == 404) {
        throw Exception('Produk tidak ditemukan di server');
      }

      if (response.statusCode != 200) {
        throw Exception('Gagal memperbarui produk: ${response.body}');
      }
    } catch (e) {
      debugPrint('Service Error [updateProduct]: $e');
      rethrow;
    }
  }

  // ======================
  // DELETE PRODUK
  // ======================
  Future<void> deleteProduct(int id, String token) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/$id'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        throw Exception('Sesi berakhir, silakan login ulang');
      }
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Gagal menghapus produk');
      }
    } catch (e) {
      debugPrint('Service Error [deleteProduct]: $e');
      rethrow;
    }
  }

  // ======================
  // GET DETAIL PRODUK
  // ======================
  Future<ProductModel> getProductDetail(int id, String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl/$id',
            ), // Memanggil endpoint detail berdasarkan ID
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        throw Exception('Sesi berakhir, silakan login ulang');
      }
      if (response.statusCode == 404) throw Exception('Produk tidak ditemukan');

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat detail produk (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);

      // Menangani berbagai kemungkinan format response (dibungkus 'data' atau tidak)
      Map<String, dynamic> data;
      if (decoded is Map) {
        data = decoded['data'] ?? decoded['produk'] ?? decoded;
      } else {
        throw Exception('Format data tidak valid');
      }

      return ProductModel.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      debugPrint('Service Error [getProductDetail]: $e');
      rethrow;
    }
  }

  // ======================
  // GET PRODUK BY KODE (Untuk Scanner)
  // ======================
  Future<ProductModel?> getProductByKode({
    required String kodeBarang,
    required String token,
  }) async {
    try {
      // Menggunakan query parameter untuk mencari berdasarkan kode
      final response = await http
          .get(
            Uri.parse('$_baseUrl?kode_barang=$kodeBarang'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      List<dynamic> listData = decoded is List
          ? decoded
          : (decoded['data'] ?? []);

      if (listData.isEmpty) return null;

      // Mencari kecocokan eksak
      for (var item in listData) {
        final p = ProductModel.fromJson(Map<String, dynamic>.from(item));
        if (p.kodeBarang.toLowerCase() == kodeBarang.toLowerCase()) {
          return p;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Service Error [getProductByKode]: $e');
      return null;
    }
  }
}
