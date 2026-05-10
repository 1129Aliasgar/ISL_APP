import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:g_one/utils/constants.dart';
import 'package:g_one/services/auth_service.dart';

class ApiService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<Map<String, dynamic>> predictFromSensors({
    required String deviceId,
    required Map<String, dynamic> sensors,
    required bool end,
    String? timestamp,
  }) async {
    try {
      final token = await AuthService.getToken();
      final body = <String, dynamic>{
        'deviceId': deviceId,
        'sensors': sensors,
        'end': end,
        'timestamp': timestamp ?? DateTime.now().toUtc().toIso8601String(),
      };
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.predictEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        final audioUrl = result['audioUrl'] as String?;
        if (audioUrl != null) {
          await _playAudio(audioUrl, 0.8);
        }
        return result;
      }
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': false,
        'message': errorBody['message'] ?? errorBody['error'] ?? 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<void> _playAudio(String url, double volume) async {
    try {
      // Set volume (0.0 to 1.0) - audioplayers supports Android, iOS, and Web
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
      
      // Play audio - works on all platforms (Android, iOS, Web)
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print('Error playing audio: $e');
      // Don't rethrow - allow the app to continue even if audio fails
    }
  }

  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }
}

