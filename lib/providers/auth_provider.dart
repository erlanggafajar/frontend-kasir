import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // Hak akses getters
  bool get isAdmin => _user?.hakAkses == 'ADMIN';
  bool get isKasir => _user?.hakAkses == 'KASIR';
  String get userRole => _user?.hakAkses ?? 'UNKNOWN';
  String get userName => _user?.name ?? 'Unknown User';
  int get userId => _user?.id ?? 0;
  int get tokoId => _user?.tokoId ?? 0;

  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    final token = await _authService.getToken();
    final user = await _authService.getUserData();

    if (token != null && user != null) {
      _token = token;
      _user = user;
      _isAuthenticated = true;

      // Update tokoId di ApiService untuk data isolation
      if (_user?.tokoId != null) {
        ApiService.updateTokoId(_user!.tokoId);
        debugPrint('Toko ID isolation enabled on startup: ${_user!.tokoId}');
      }
    } else {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      if (result['success'] == true) {
        _user = result['user'];
        _token = result['token'];
        _isAuthenticated = true;

        // Update token di semua services
        _updateServiceTokens();

        _isLoading = false;
        notifyListeners();

        return {'success': true, 'message': 'Login berhasil'};
      } else {
        _isLoading = false;
        notifyListeners();

        return {
          'success': false,
          'message': result['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': e.toString()};
    }
  }

  // Method untuk update token di semua services
  void _updateServiceTokens() {
    if (_token != null) {
      // Update token di service yang membutuhkan
      // Ini akan dipanggil setiap kali login berhasil
      debugPrint('Token updated for all services');

      // Update tokoId di ApiService untuk data isolation
      if (_user?.tokoId != null) {
        ApiService.updateTokoId(_user!.tokoId);
        debugPrint('Toko ID isolation enabled: ${_user!.tokoId}');
      }

      // Update tokoId di ProductProvider untuk data isolation
      // Note: ProductProvider akan diupdate melalui listener di main.dart
      // atau screen yang menggunakan kedua provider
    }
  }

  // Method untuk handle authentication error
  void handleAuthError(String error) {
    debugPrint('Auth Error: $error');

    // Check jika error terkait authentication
    if (error.toLowerCase().contains('unauthenticated') ||
        error.toLowerCase().contains('token') ||
        error.toLowerCase().contains('authorized')) {
      debugPrint('Authentication error detected, logging out...');
      logout();
    }
  }

  // Method untuk refresh token jika perlu
  Future<bool> refreshTokenIfNeeded() async {
    if (_token == null || _token!.isEmpty) {
      debugPrint('No token to refresh');
      return false;
    }

    try {
      // Coba refresh token (jika API support)
      debugPrint('Attempting to refresh token...');
      // Implementasi refresh token jika API mendukung

      return true;
    } catch (e) {
      debugPrint('Failed to refresh token: $e');
      handleAuthError(e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.register(
        nama: nama,
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': e.toString()};
    }
  }

  // Method untuk update user profile dengan API backend
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // API call ke backend untuk update profile
      final result = await ApiService.put(
        '/user/profile',
        body: {'name': name, if (email != null) 'email': email},
        token: _token,
      );

      if (result['success'] == true) {
        // Update user object di provider
        if (_user != null) {
          _user = User(
            id: _user!.id,
            name: name,
            email: email ?? _user!.email,
            tokoId: _user!.tokoId,
            hakAkses: _user!.hakAkses,
          );
        }
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': 'Gagal memperbarui profil: $e'};
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();

    _user = null;
    _token = null;
    _isAuthenticated = false;
    _isLoading = false;

    notifyListeners();
  }

  // Method untuk mengubah password dengan API backend
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    String? newPasswordConfirmation,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('=== CHANGE PASSWORD START ===');
      debugPrint('User ID: ${_user?.id}');
      debugPrint('User Role: ${_user?.hakAkses}');
      debugPrint('Token: ${_token?.substring(0, 20) ?? 'null'}...');

      // API call ke backend untuk ubah password
      final result = await ApiService.put(
        '/user/password',
        body: {
          'old_password': oldPassword,
          'new_password': newPassword,
          if (newPasswordConfirmation != null)
            'new_password_confirmation': newPasswordConfirmation,
        },
        token: _token,
      );

      debugPrint('Change password result: $result');

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('CHANGE PASSWORD ERROR: $e');
      _isLoading = false;
      notifyListeners();

      return {'success': false, 'message': 'Gagal mengubah password: $e'};
    }
  }

  // Method untuk cek hak akses
  bool canAccessTransactionDetail(
    int transactionUserId, {
    String? transactionKasirName,
  }) {
    debugPrint('=== ACCESS CHECK ===');
    debugPrint('User role: $userRole');
    debugPrint('User ID: $userId');
    debugPrint('User Name: $userName');
    debugPrint('Transaction User ID: $transactionUserId');
    debugPrint('Transaction Kasir Name: $transactionKasirName');
    debugPrint('Is Admin: $isAdmin');
    debugPrint('Is Kasir: $isKasir');

    // Admin bisa akses semua transaksi
    if (isAdmin) {
      debugPrint('ACCESS GRANTED: Admin can access all transactions');
      return true;
    }

    // Kasir hanya bisa akses transaksi yang dibuat olehnya
    if (isKasir) {
      // Primary check: userId match
      if (transactionUserId == userId) {
        debugPrint(
          'KASIR ACCESS GRANTED: User ID match ($transactionUserId == $userId)',
        );
        return true;
      }

      // Secondary check: namaKasir match (for backward compatibility)
      if (transactionKasirName != null &&
          transactionKasirName.trim().isNotEmpty &&
          transactionKasirName.trim() == userName.trim()) {
        debugPrint(
          'KASIR ACCESS GRANTED: Kasir name match ($transactionKasirName == $userName)',
        );
        return true;
      }

      debugPrint(
        'KASIR ACCESS DENIED: Neither user ID ($transactionUserId != $userId) nor kasir name match',
      );
      return false;
    }

    debugPrint('ACCESS DENIED: Unknown role');
    return false;
  }

  bool canEditTransaction(
    int transactionUserId, {
    String? transactionKasirName,
  }) {
    debugPrint('=== EDIT ACCESS CHECK ===');
    debugPrint('User role: $userRole');
    debugPrint('User ID: $userId');
    debugPrint('User Name: $userName');
    debugPrint('Transaction User ID: $transactionUserId');
    debugPrint('Transaction Kasir Name: $transactionKasirName');

    // EDIT TRANSAKSI DILARAK UNTUK SEMUA ROLE
    // Alasan: Edit transaksi bisa mengubah data keuangan dan sangat berbahaya
    debugPrint(
      'EDIT DENIED: Edit transactions is disabled for security reasons',
    );
    return false;
  }

  bool canDeleteTransaction(
    int transactionUserId, {
    String? transactionKasirName,
  }) {
    debugPrint('=== DELETE ACCESS CHECK ===');
    debugPrint('User role: $userRole');
    debugPrint('User ID: $userId');
    debugPrint('User Name: $userName');
    debugPrint('Transaction User ID: $transactionUserId');
    debugPrint('Transaction Kasir Name: $transactionKasirName');
    debugPrint('Is Admin: $isAdmin');
    debugPrint('Is Kasir: $isKasir');
    debugPrint('User object: ${_user?.toJson()}');

    // Hanya admin yang bisa hapus transaksi
    if (isAdmin) {
      debugPrint('✅ DELETE GRANTED: Admin can delete all transactions');
      return true;
    }

    // Kasir tidak bisa hapus transaksi (bahkan yang dibuat sendiri)
    if (isKasir) {
      debugPrint('❌ DELETE DENIED: Kasir cannot delete transactions');
      return false;
    }

    debugPrint('❌ DELETE DENIED: Unknown role - $userRole');
    return false;
  }
}
