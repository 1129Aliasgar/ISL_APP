import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/utils/constants.dart';

class PredictSocketService {
  PredictSocketService._();

  static io.Socket? _socket;
  static String? _deviceId;
  static bool _joined = false;

  static final StreamController<Map<String, dynamic>> _predictionController =
      StreamController<Map<String, dynamic>>.broadcast();
  static final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  static final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  static final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  static Stream<Map<String, dynamic>> get predictionStream =>
      _predictionController.stream;
  static Stream<String> get statusStream => _statusController.stream;
  static Stream<String> get errorStream => _errorController.stream;
  static Stream<bool> get connectionStream => _connectionController.stream;

  static bool get isConnected => _socket?.connected == true && _joined;

  static Map<String, dynamic> _normalizePayload(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static Future<bool> connect({required String deviceId}) async {
    if (_socket?.connected == true && _deviceId == deviceId && _joined) {
      return true;
    }

    await disconnect();

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      _errorController.add('Missing auth token. Please login again.');
      return false;
    }

    _deviceId = deviceId;
    _joined = false;

    final completer = Completer<bool>();
    Timer? joinTimeout;

    _socket = io.io(
      '${AppConstants.wsBaseUrl}/predict',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'ngrok-skip-browser-warning': 'true'})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _connectionController.add(true);
        _statusController.add('Connected to prediction stream');
        _socket!.emit('join', {'deviceId': deviceId, 'token': token});

        joinTimeout = Timer(const Duration(seconds: 8), () {
          if (!completer.isCompleted) {
            completer.complete(false);
            _errorController.add('Timed out joining predict room');
          }
        });
      })
      ..on('joined', (data) {
        _joined = true;
        _statusController.add('Listening for predictions...');
        joinTimeout?.cancel();
        if (!completer.isCompleted) completer.complete(true);
      })
      ..on('status', (data) {
        final map = _normalizePayload(data);
        if (map['state'] == 'processing') {
          _statusController.add('Processing gesture...');
        }
      })
      ..on('prediction:result', (data) {
        final map = _normalizePayload(data);
        if (map.isNotEmpty) {
          _predictionController.add(map);
        }
      })
      ..on('prediction:error', (data) {
        final map = _normalizePayload(data);
        _errorController.add(map['message']?.toString() ?? 'Prediction error');
      })
      ..on('error', (data) {
        final map = _normalizePayload(data);
        _errorController.add(map['message']?.toString() ?? 'Socket error');
        joinTimeout?.cancel();
        if (!completer.isCompleted) completer.complete(false);
      })
      ..onDisconnect((_) {
        _joined = false;
        _connectionController.add(false);
        _statusController.add('Disconnected');
        joinTimeout?.cancel();
        if (!completer.isCompleted) completer.complete(false);
      })
      ..onConnectError((err) {
        _joined = false;
        _connectionController.add(false);
        _errorController.add('Connection failed: $err');
        joinTimeout?.cancel();
        if (!completer.isCompleted) completer.complete(false);
      });

    _socket!.connect();

    return completer.future;
  }

  static Future<void> disconnect() async {
    _joined = false;
    if (_socket != null) {
      if (_deviceId != null) {
        _socket!.emit('leave', {'deviceId': _deviceId});
      }
      _socket!.dispose();
      _socket = null;
    }
    _deviceId = null;
    _connectionController.add(false);
  }
}
