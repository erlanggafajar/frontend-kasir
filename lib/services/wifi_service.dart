import 'package:shared_preferences/shared_preferences.dart';

class WiFiService {
  static const String _wifiNameKey = 'wifi_name';
  static const String _wifiPasswordKey = 'wifi_password';
  static const String _wifiSecurityKey = 'wifi_security';

  // Load WiFi settings from SharedPreferences
  static Future<Map<String, String>> getWiFiSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wifiName = prefs.getString(_wifiNameKey) ?? 'Kasir-WiFi';
      final wifiPassword = prefs.getString(_wifiPasswordKey) ?? 'Kasir123456';
      final wifiSecurity = prefs.getString(_wifiSecurityKey) ?? 'Super Kuat';

      return {
        'name': wifiName,
        'password': wifiPassword,
        'security': wifiSecurity,
      };
    } catch (e) {
      return {
        'name': 'Kasir-WiFi',
        'password': 'Kasir123456',
        'security': 'Super Kuat',
      };
    }
  }

  // Check if WiFi has been configured before
  static Future<bool> isWiFiConfigured() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_wifiNameKey) &&
          prefs.containsKey(_wifiPasswordKey);
    } catch (e) {
      return false;
    }
  }

  // Save WiFi settings to SharedPreferences (only if not configured before)
  static Future<bool> saveWiFiSettingsOnce({
    required String name,
    required String password,
    required String security,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if already configured
      if (prefs.containsKey(_wifiNameKey) &&
          prefs.containsKey(_wifiPasswordKey)) {
        return false; // Already configured, deny save
      }

      await prefs.setString(_wifiNameKey, name);
      await prefs.setString(_wifiPasswordKey, password);
      await prefs.setString(_wifiSecurityKey, security);
      return true; // Successfully saved
    } catch (e) {
      return false;
    }
  }

  // Save WiFi settings to SharedPreferences (force update - for admin use)
  static Future<void> saveWiFiSettings({
    required String name,
    required String password,
    required String security,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_wifiNameKey, name);
      await prefs.setString(_wifiPasswordKey, password);
      await prefs.setString(_wifiSecurityKey, security);
    } catch (e) {
      // Handle error silently or log if needed
    }
  }

  // Check if store has WiFi settings
  static Future<bool> hasWiFiSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wifiName = prefs.getString(_wifiNameKey);
      final wifiPassword = prefs.getString(_wifiPasswordKey);

      // Return true only if both name and password are set and not default values
      return wifiName != null &&
          wifiPassword != null &&
          wifiName.isNotEmpty &&
          wifiPassword.isNotEmpty &&
          wifiName != 'Kasir-WiFi' &&
          wifiPassword != 'Kasir123456';
    } catch (e) {
      return false;
    }
  }

  // Delete WiFi settings (admin only)
  static Future<void> deleteWiFiSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_wifiNameKey);
      await prefs.remove(_wifiPasswordKey);
      await prefs.remove(_wifiSecurityKey);
    } catch (e) {
      // Handle error silently or log if needed
    }
  }

  // Format WiFi info for display
  static String formatWiFiInfo(String name, String password) {
    return 'WiFi: $name\nPassword: $password';
  }
}
