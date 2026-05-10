class AppConstants {
  AppConstants._();

  static const String appName = 'G-ONE';
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

  // API
  // Override at build time:
  // flutter build apk --release --dart-define=API_BASE_URL=https://<host>/api
  static const String baseUrl = 'https://burthensome-emerald-libidinally.ngrok-free.dev/api';
  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String profileEndpoint = '/auth/me';
  static const String predictEndpoint = '/predict';
}


