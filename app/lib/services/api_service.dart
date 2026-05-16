import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/utils/constants.dart';

class ApiService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();

  static Stream<bool> get speakingStream => _speakingController.stream;

  static Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      };

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Poll latest glove prediction saved by backend after ESP32 `/api/predict`.
  static Future<Map<String, dynamic>> fetchLatestPrediction(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.predictEndpoint}/latest/$deviceId'),
        headers: await _authHeaders(),
      );

      if (response.statusCode == 404) {
        return {'success': false, 'notFound': true};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'success': false,
        'message': errorBody['message'] ?? errorBody['error'] ?? 'Server error',
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<bool> playAudioFromUrl(String url, {double volume = 0.9}) async {
    try {
      _speakingController.add(true);
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));

      final response = await http.get(
        Uri.parse(url),
        headers: const {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode != 200) {
        _speakingController.add(false);
        return false;
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(response.bodyBytes));

      unawaited(
        _audioPlayer.onPlayerComplete.first.then((_) {
          _speakingController.add(false);
        }),
      );
      return true;
    } catch (e) {
      _speakingController.add(false);
      return false;
    }
  }

  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _speakingController.add(false);
    } catch (_) {}
  }
}
