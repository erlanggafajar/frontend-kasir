import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login Method
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiService.post(
        '/login',
        body: {'email': email, 'password': password},
      );

      if (response['status'] == 'success') {
        final token = response['token'];
        final userData = response['user'];

        // Simpan token dan user data
        await _saveToken(token);
        await _saveUserData(userData);

        return {
          'success': true,
          'user': User.fromJson(userData),
          'token': token,
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Login gagal',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // Register Method
  Future<Map<String, dynamic>> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        '/pendaftaran',
        body: {'nama': nama, 'email': email, 'password': password},
      );

      if (response['message'] == 'Berhasil Mendaftar') {
        return {
          'success': true,
          'message': response['message'],
          'id': response['id'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Pendaftaran gagal',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<bool> logout() async {
    try {
      await _clearAuthData();
      return true;
    } catch (e) {
      await _clearAuthData();
      return true;
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<User?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(userData));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
