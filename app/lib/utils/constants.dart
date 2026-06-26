class AppConstants {
  AppConstants._();

  static const String appName = 'G-ONE';
  static const String logoAsset = 'assets/logo.jpeg';
  static const Duration splashDelay = Duration(seconds: 2);

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeHome = '/home';
  static const String routeAccount = '/account';
  static const String routeGameController = '/game-controller';
  static const String routeVideoCalling = '/video-calling';
  static const String routeSettings = '/settings';

  // REST API (auth only + legacy)
  // Override at build time:
  // flutter build apk --release --dart-define=API_BASE_URL=https://<host>/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://burthensome-emerald-libidinally.ngrok-free.dev/api',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'https://burthensome-emerald-libidinally.ngrok-free.dev',
  );

  /// External laptop: YOLO + gesture → sensor template → streams to our backend.
  static const String gestureDeviceUrl = String.fromEnvironment(
    'GESTURE_DEVICE_URL',
    defaultValue: 'https://6deb-202-141-53-245.ngrok-free.app',
  );

  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String profileEndpoint = '/auth/me';
  static const String predictEndpoint = '/predict';
}
