import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:g_one/utils/constants.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _deviceIdKey = 'device_id';
  static const String _sessionKey = 'is_logged_in';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSession = prefs.getBool(_sessionKey) ?? false;
    final token = prefs.getString(_tokenKey);
    return hasSession && token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_deviceIdKey);
    await prefs.setBool(_sessionKey, false);
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.registerEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'deviceId': deviceId,
      }),
    );
    return _handleAuthResponse(response);
  }

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    return _handleAuthResponse(response);
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? password,
    String? deviceId,
  }) async {
    final token = await getToken();
    final response = await http.patch(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      }),
    );
    final result = _handlePlainResponse(response);
    if (result['success'] == true && result['user'] is Map<String, dynamic>) {
      final user = result['user'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      if (user['deviceId'] != null) {
        await prefs.setString(_deviceIdKey, user['deviceId'] as String);
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _handlePlainResponse(response);
  }

  static Future<Map<String, dynamic>> _handleAuthResponse(http.Response response) async {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = body['token'] as String?;
      final user = body['user'] as Map<String, dynamic>?;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setBool(_sessionKey, true);
        if (user != null && user['deviceId'] != null) {
          await prefs.setString(_deviceIdKey, user['deviceId'] as String);
        }
      }
      return body;
    }
    return {'success': false, 'message': body['message'] ?? 'Request failed'};
  }

  static Map<String, dynamic> _handlePlainResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return body;
    return {'success': false, 'message': body['message'] ?? 'Request failed'};
  }
}
