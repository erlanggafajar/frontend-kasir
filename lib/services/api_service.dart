import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Ganti dengan URL API Laravel Anda
  // static const String baseUrl = 'http://127.0.0.1:8000/api';
  static const String baseUrl = 'https://kasir.tgh.my.id/api';

  // Store current tokoId for data isolation
  static int _currentTokoId = 0;

  // Update tokoId for data filtering
  static void updateTokoId(int tokoId) {
    if (_currentTokoId != tokoId) {
      debugPrint('ApiService: Toko ID CHANGED from $_currentTokoId to $tokoId');
      _currentTokoId = tokoId;
      debugPrint('ApiService: Toko ID updated to $_currentTokoId');
    } else {
      debugPrint('ApiService: Toko ID unchanged ($_currentTokoId)');
    }
  }

  // Get current tokoId
  static int get currentTokoId => _currentTokoId;

  // Timeout settings
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  // Untuk Android Emulator gunakan: http://10.0.2.2:8000/api
  // Untuk iOS Simulator gunakan: http://localhost:8000/api
  // Untuk Device fisik gunakan IP komputer Anda

  static Map<String, String> getHeaders({String? token}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    return _retryOperation(() async {
      try {
        // Add tokoId to request body for data isolation
        final Map<String, dynamic> finalBody = Map.from(body);
        if (_currentTokoId > 0) {
          finalBody['toko_id'] = _currentTokoId;
        }

        debugPrint('POST Request: $baseUrl$endpoint');
        debugPrint('Toko ID Filter: $_currentTokoId');
        debugPrint('Request Body: ${finalBody.toString()}');

        final response = await http
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: getHeaders(token: token),
              body: json.encode(finalBody),
            )
            .timeout(_timeout);

        return _handleResponse(response);
      } on SocketException catch (e) {
        throw Exception(
          'Koneksi ke server terputus. Pastikan koneksi internet stabil: ${e.message}',
        );
      } on HttpException catch (e) {
        throw Exception('Tidak dapat terhubung ke server: ${e.message}');
      } on TimeoutException catch (e) {
        throw Exception(
          'Server terlalu lama merespons. Coba lagi: ${e.message}',
        );
      } catch (e) {
        throw Exception('Gagal terhubung ke server: ${e.toString()}');
      }
    });
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
  }) async {
    try {
      // Add tokoId filter for data isolation
      String finalEndpoint = endpoint;
      if (_currentTokoId > 0) {
        final separator = endpoint.contains('?') ? '&' : '?';
        finalEndpoint = '$endpoint${separator}toko_id=$_currentTokoId';
      }

      final url = Uri.parse('$baseUrl$finalEndpoint');

      debugPrint('GET Request: $url');
      debugPrint('Toko ID Filter: $_currentTokoId');

      final response = await http
          .get(url, headers: _buildHeaders(token))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body Length: ${response.body.length}');

      // Check for empty response body
      if (response.body.isEmpty || response.body.trim().isEmpty) {
        debugPrint('Empty response body');

        // If status is 2xx, treat as success with empty data
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return {'data': null};
        }

        throw Exception('Empty response from server');
      }

      // Try to decode JSON
      try {
        final data = json.decode(response.body);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return data is Map<String, dynamic> ? data : {'data': data};
        } else {
          throw Exception(
            data['message'] ??
                'Request failed with status ${response.statusCode}',
          );
        }
      } on FormatException catch (e) {
        debugPrint('JSON decode error: $e');
        debugPrint('Response body: ${response.body}');
        throw Exception('Invalid JSON response from server');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Connection timeout');
    } catch (e) {
      debugPrint('API Error: $e');
      rethrow;
    }
  }

  static Map<String, String> _buildHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    return _retryOperation(() async {
      try {
        // Add tokoId to request body for data isolation
        final Map<String, dynamic> finalBody = Map.from(body);
        if (_currentTokoId > 0) {
          finalBody['toko_id'] = _currentTokoId;
        }

        // Add tokoId to endpoint URL for additional filtering
        String finalEndpoint = endpoint;
        if (_currentTokoId > 0 && !endpoint.contains('toko_id')) {
          final separator = endpoint.contains('?') ? '&' : '?';
          finalEndpoint = '$endpoint${separator}toko_id=$_currentTokoId';
        }

        debugPrint('PUT Request: $baseUrl$finalEndpoint');
        debugPrint('Toko ID Filter: $_currentTokoId');
        debugPrint('Request Body: ${finalBody.toString()}');

        final response = await http
            .put(
              Uri.parse('$baseUrl$finalEndpoint'),
              headers: getHeaders(token: token),
              body: json.encode(finalBody),
            )
            .timeout(_timeout);

        return _handleResponse(response);
      } on SocketException catch (e) {
        throw Exception(
          'Koneksi ke server terputus. Pastikan koneksi internet stabil: ${e.message}',
        );
      } on HttpException catch (e) {
        throw Exception('Tidak dapat terhubung ke server: ${e.message}');
      } on TimeoutException catch (e) {
        throw Exception(
          'Server terlalu lama merespons. Coba lagi: ${e.message}',
        );
      } catch (e) {
        throw Exception('Gagal terhubung ke server: ${e.toString()}');
      }
    });
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
  }) async {
    return _retryOperation(() async {
      try {
        // Add tokoId to endpoint URL for data isolation
        String finalEndpoint = endpoint;
        if (_currentTokoId > 0 && !endpoint.contains('toko_id')) {
          final separator = endpoint.contains('?') ? '&' : '?';
          finalEndpoint = '$endpoint${separator}toko_id=$_currentTokoId';
        }

        debugPrint('DELETE Request: $baseUrl$finalEndpoint');
        debugPrint('Toko ID Filter: $_currentTokoId');

        final response = await http
            .delete(
              Uri.parse('$baseUrl$finalEndpoint'),
              headers: getHeaders(token: token),
            )
            .timeout(_timeout);

        return _handleResponse(response);
      } on SocketException catch (e) {
        throw Exception(
          'Koneksi ke server terputus. Pastikan koneksi internet stabil: ${e.message}',
        );
      } on HttpException catch (e) {
        throw Exception('Tidak dapat terhubung ke server: ${e.message}');
      } on TimeoutException catch (e) {
        throw Exception(
          'Server terlalu lama merespons. Coba lagi: ${e.message}',
        );
      } catch (e) {
        throw Exception('Gagal terhubung ke server: ${e.toString()}');
      }
    });
  }

  static Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = _maxRetries,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempt < maxRetries) {
          // Exponential backoff: wait 1s, 2s, 4s
          final delay = Duration(milliseconds: 1000 * (1 << attempt));
          await Future.delayed(delay);
        }
      }
    }

    throw lastException!;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Terjadi kesalahan pada server');
    }
  }
}
