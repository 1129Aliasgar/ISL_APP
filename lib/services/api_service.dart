import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:g_one/utils/constants.dart';

class ApiService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<Map<String, dynamic>> speak({
    required String text,
    String? language,
    double? pitch,
    double? volume,
    double? speed,
    String? voice,
  }) async {
    try {
      final body = <String, dynamic>{
        'text': text,
      };

      if (language != null) body['language'] = language;
      if (pitch != null) body['pitch'] = pitch;
      if (volume != null) body['volume'] = volume;
      if (speed != null) body['speed'] = speed;
      if (voice != null) body['voice'] = voice;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.speakEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        
        // If audio URL is provided, play it
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'] as Map<String, dynamic>;
          final audioUrl = data['audioUrl'] as String?;
          
          if (audioUrl != null) {
            // Construct full audio URL
            // audioUrl from backend is like: /api/audio/filename.mp3
            // baseUrl is like: http://localhost:8000/api or https://your-domain.com/api
            // We need: http://localhost:8000/api/audio/filename.mp3 or https://your-domain.com/api/audio/filename.mp3
            String fullAudioUrl;
            if (audioUrl.startsWith('http://') || audioUrl.startsWith('https://')) {
              // Already a full URL
              fullAudioUrl = audioUrl;
            } else if (audioUrl.startsWith('/')) {
              // Relative URL - construct from baseUrl
              final baseUrlWithoutApi = AppConstants.baseUrl.replaceAll('/api', '');
              fullAudioUrl = '$baseUrlWithoutApi$audioUrl';
            } else {
              // Relative path without leading slash
              final baseUrlWithoutApi = AppConstants.baseUrl.replaceAll('/api', '');
              fullAudioUrl = '$baseUrlWithoutApi/api/$audioUrl';
            }
            
            await _playAudio(fullAudioUrl, volume ?? 0.8);
          }
        }
        
        return result;
      } else {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'message': errorBody['message'] ?? 'Server error: ${response.statusCode}',
        };
      }
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

  // Legacy method for backward compatibility
  static Future<Map<String, dynamic>> textToSpeech(String text) async {
    return speak(text: text);
  }
}

