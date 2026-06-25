import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:g_one/services/settings_service.dart';

class SpeechService {
  SpeechService._();

  static final FlutterTts _tts = FlutterTts();
  static final StreamController<bool> _speakingController =
      StreamController<bool>.broadcast();
  static bool _initialized = false;

  static Stream<bool> get speakingStream => _speakingController.stream;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _tts.setCompletionHandler(() => _speakingController.add(false));
    _tts.setCancelHandler(() => _speakingController.add(false));
    _tts.setErrorHandler((_) => _speakingController.add(false));
    _initialized = true;
  }

  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await _ensureInitialized();
    final settings = await SettingsService.getSettings();

    await _tts.setLanguage(_mapLanguage(settings['language'] as String));
    await _tts.setPitch(settings['pitch'] as double);
    await _tts.setSpeechRate(_mapSpeechRate(settings['speed'] as double));
    await _tts.setVolume(settings['volume'] as double);

    _speakingController.add(true);
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _ensureInitialized();
    await _tts.stop();
    _speakingController.add(false);
  }

  static String _mapLanguage(String code) {
    switch (code) {
      case 'hi':
        return 'hi-IN';
      case 'bn':
        return 'bn-IN';
      case 'gu':
        return 'gu-IN';
      case 'mr':
        return 'mr-IN';
      case 'ta':
        return 'ta-IN';
      case 'te':
        return 'te-IN';
      case 'pa':
        return 'pa-IN';
      default:
        return 'en-US';
    }
  }

  static double _mapSpeechRate(double speed) {
    return (0.35 + (speed * 0.35)).clamp(0.2, 1.0);
  }
}

/// Simple label map until full translation service is added.
class GestureSpeechMapper {
  static const Map<String, String> _phrases = {
    'A': 'A',
    'B': 'B',
    'C': 'C',
    'HELLO': 'Hello',
    'HI': 'Hi',
  };

  static String phraseFor(String character) {
    final key = character.trim().toUpperCase();
    return _phrases[key] ?? character;
  }
}
