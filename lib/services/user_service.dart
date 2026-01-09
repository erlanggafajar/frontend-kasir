import 'api_service.dart';
import 'package:flutter/foundation.dart';

class UserService {
  static Future<Map<String, dynamic>?> getUserById(
    int userId, {
    String? token,
  }) async {
    try {
      // Validate userId
      if (userId <= 0) {
        debugPrint('Invalid userId: $userId');
        return null;
      }

      debugPrint('Fetching user data for userId: $userId');

      final response = await ApiService.get('/user/$userId', token: token)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Timeout fetching user $userId');
              return {};
            },
          );

      debugPrint('User $userId response: $response');

      // Check if response is empty or null
      if (response.isEmpty) {
        debugPrint('Empty response for user $userId');
        return null;
      }

      // Handle different response structures
      if (response['data'] != null) {
        return response['data'] is Map ? response['data'] : null;
      }

      // If response itself is user data
      if (response['name'] != null || response['id'] != null) {
        return response;
      }

      debugPrint('Unexpected response structure for user $userId');
      return null;
    } catch (e) {
      debugPrint('Error fetching user $userId: $e');
      // Don't rethrow, just return null for graceful degradation
      return null;
    }
  }

  static Future<String?> getUserNameById(int userId, {String? token}) async {
    // DISABLED: Avoid API calls that cause 401 authorization errors
    // Let the fallback logic in screens handle the names from transaction data
    debugPrint(
      'UserService.getUserNameById disabled - using fallback from transaction data',
    );
    return null;
  }

  static Future<Map<String, dynamic>> getAllUsers({String? token}) async {
    try {
      final response = await ApiService.get('/user', token: token);
      return response;
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      rethrow;
    }
  }
}
