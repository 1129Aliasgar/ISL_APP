class AppConstants {
  AppConstants._();

  static const String appName = 'G-ONE';
  static const Duration splashDelay = Duration(seconds: 2);

  // Routes
  static const String routeSplash = '/';
  static const String routeHome = '/home';
  static const String routeGameController = '/game-controller';
  static const String routeVideoCalling = '/video-calling';
  static const String routeSettings = '/settings';

  // API
  static const String baseUrl = 'http://localhost:8000/api';
  static const String textToSpeechEndpoint = '/text-to-speech';
  static const String speakEndpoint = '/speak';
  static const String voicesEndpoint = '/voices';
}


