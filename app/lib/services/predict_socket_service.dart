import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/utils/constants.dart';

class PredictSocketService {
  PredictSocketService._();

  static io.Socket? _socket;
  static String? _deviceId;

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

  static bool get isConnected => _socket?.connected == true;

  static Future<bool> connect({required String deviceId}) async {
    if (_socket?.connected == true && _deviceId == deviceId) {
      return true;
    }

    await disconnect();

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      _errorController.add('Missing auth token. Please login again.');
      return false;
    }

    _deviceId = deviceId;
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
      })
      ..on('joined', (_) {
        _statusController.add('Listening for predictions...');
      })
      ..on('status', (data) {
        if (data is Map && data['state'] == 'processing') {
          _statusController.add('Processing gesture...');
        }
      })
      ..on('prediction:result', (data) {
        if (data is Map) {
          _predictionController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('prediction:error', (data) {
        if (data is Map) {
          _errorController.add(data['message']?.toString() ?? 'Prediction error');
        }
      })
      ..on('error', (data) {
        if (data is Map) {
          _errorController.add(data['message']?.toString() ?? 'Socket error');
        }
      })
      ..onDisconnect((_) {
        _connectionController.add(false);
        _statusController.add('Disconnected');
      })
      ..onConnectError((err) {
        _connectionController.add(false);
        _errorController.add('Connection failed: $err');
      });

    _socket!.connect();

    await Future<void>.delayed(const Duration(milliseconds: 800));
    return _socket?.connected == true;
  }

  static Future<void> disconnect() async {
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
