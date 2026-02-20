import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyLanguage = 'selected_language';
  static const String _keyPitch = 'speech_pitch';
  static const String _keyVolume = 'speech_volume';
  static const String _keySpeed = 'speech_speed';

  // Default values
  static const String defaultLanguage = 'hi';
  static const double defaultPitch = 1.0;
  static const double defaultVolume = 0.8;
  static const double defaultSpeed = 1.0;

  // Get settings
  static Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'language': prefs.getString(_keyLanguage) ?? defaultLanguage,
      'pitch': prefs.getDouble(_keyPitch) ?? defaultPitch,
      'volume': prefs.getDouble(_keyVolume) ?? defaultVolume,
      'speed': prefs.getDouble(_keySpeed) ?? defaultSpeed,
    };
  }

  // Save language
  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, language);
  }

  // Save pitch
  static Future<void> savePitch(double pitch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPitch, pitch);
  }

  // Save volume
  static Future<void> saveVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, volume);
  }

  // Save speed
  static Future<void> saveSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySpeed, speed);
  }

  // Save all settings
  static Future<void> saveAllSettings({
    String? language,
    double? pitch,
    double? volume,
    double? speed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (language != null) await prefs.setString(_keyLanguage, language);
    if (pitch != null) await prefs.setDouble(_keyPitch, pitch);
    if (volume != null) await prefs.setDouble(_keyVolume, volume);
    if (speed != null) await prefs.setDouble(_keySpeed, speed);
  }
}

