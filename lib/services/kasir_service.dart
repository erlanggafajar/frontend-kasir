import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/kasir_model.dart';

class KasirService {
  static const String _baseUrl = 'https://kasir.tgh.my.id/api/admin/users';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'Authorization': 'Bearer $token',
  };

  // ======================
  // GET LIST KASIR
  // ======================
  Future<List<KasirModel>> getKasir({required String token}) async {
    debugPrint('GET KASIR: Token length: ${token.length}');
    debugPrint(
      'GET KASIR: Token preview: ${token.length > 20 ? "${token.substring(0, 20)}..." : token}',
    );

    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: _headers(token),
    );

    debugPrint('LIST STATUS: ${response.statusCode}');
    debugPrint('LIST BODY: ${response.body}');

    if (response.statusCode == 401) {
      debugPrint('AUTH ERROR: Token expired or invalid');
      throw Exception('Unauthenticated');
    }

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat kasir (${response.statusCode})');
    }

    if (response.body.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(response.body);

    List listData;

    if (decoded is List) {
      listData = decoded;
    } else if (decoded is Map && decoded['data'] is List) {
      listData = decoded['data'];
    } else {
      throw Exception('Format response user tidak dikenali');
    }

    return listData
        .where(
          (e) =>
              e is Map && e['hak_akses'] != null && e['hak_akses'] == 'KASIR',
        )
        .map<KasirModel>(
          (e) => KasirModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  // ======================
  // GET DETAIL USER
  // ======================
  Future<KasirModel> getKasirDetail({
    required int id,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers(token),
    );

    debugPrint('DETAIL STATUS: ${response.statusCode}');
    debugPrint('DETAIL BODY: ${response.body}');
    debugPrint('DETAIL HEADERS: ${response.headers}');

    if (response.statusCode == 401) {
      throw Exception('Session login berakhir');
    }

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat detail user');
    }

    // ⛔ BODY KOSONG
    if (response.body.isEmpty) {
      throw Exception(
        'API mengembalikan body kosong. Periksa controller Laravel.',
      );
    }

    // ⛔ BUKAN JSON
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Response bukan JSON (content-type: $contentType)');
    }

    final decoded = jsonDecode(response.body);

    final Map<String, dynamic> data =
        decoded is Map && decoded.containsKey('data')
        ? Map<String, dynamic>.from(decoded['data'])
        : Map<String, dynamic>.from(decoded);

    return KasirModel.fromJson(data);
  }

  // ======================
  // CREATE KASIR
  // ======================
  Future<void> createKasir({
    required String name,
    required String email,
    required String password,
    required String token,
  }) async {
    debugPrint('CREATE KASIR: Token length: ${token.length}');
    debugPrint('CREATE KASIR: URL: $_baseUrl');

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers(token),
      body: jsonEncode({
        'nama': name,
        'email': email,
        'password': password,
        'hak_akses': 'KASIR',
      }),
    );

    debugPrint('CREATE STATUS: ${response.statusCode}');
    debugPrint('CREATE BODY: ${response.body}');

    if (response.statusCode == 401) {
      debugPrint('AUTH ERROR: Token expired or invalid during create');
      throw Exception('Unauthenticated');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal menambah kasir: ${response.body}');
    }
  }

  // ======================
  // UPDATE KASIR
  // ======================
  Future<void> updateKasir({
    required int id,
    required String name,
    required String email,
    String? password,
    required String token,
  }) async {
    final Map<String, dynamic> body = {
      'nama': name,
      'email': email,
      'hak_akses': 'KASIR',
    };

    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal update kasir');
    }
  }

  // ======================
  // DELETE KASIR
  // ======================
  Future<void> deleteKasir({required int id, required String token}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus kasir');
    }
  }
}
