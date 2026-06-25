import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:g_one/utils/constants.dart';

/// Calls the external gesture device (YOLO + template mapper on another laptop).
class GestureDeviceApiService {
  static const _headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<Map<String, dynamic>> submitGesture({
    required String gesture,
    required String deviceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.gestureDeviceUrl}/gesture'),
        headers: _headers,
        body: jsonEncode({
          'gesture': gesture,
          'deviceId': deviceId,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...body};
      }

      return {
        'success': false,
        'message': body['message']?.toString() ?? 'Gesture device error',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gesture device unreachable: ${e.toString()}',
      };
    }
  }
}
