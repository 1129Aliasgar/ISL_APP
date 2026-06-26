import 'dart:async';
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/services/camera_yolo_service.dart';
import 'package:g_one/services/predict_socket_service.dart';
import 'package:g_one/services/speech_service.dart';
import 'package:g_one/services/gesture_device_api_service.dart';

enum GestureSessionState {
  disconnected,
  connecting,
  connected,
  capturing,
  processing,
  speaking,
}

class GestureSessionService {
  GestureSessionService._();

  static final CameraYoloService _camera = CameraYoloService();
  static final StreamController<GestureSessionState> _stateController =
      StreamController<GestureSessionState>.broadcast();
  static final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  static final StreamController<String> _lastPredictionController =
      StreamController<String>.broadcast();
  static final StreamController<String?> _pendingGestureController =
      StreamController<String?>.broadcast();

  static Stream<GestureSessionState> get stateStream => _stateController.stream;
  static Stream<String> get statusStream => _statusController.stream;
  static Stream<String> get lastPredictionStream =>
      _lastPredictionController.stream;
  static Stream<String?> get pendingGestureStream =>
      _pendingGestureController.stream;
  static Stream<String> get cameraGestureStream => _camera.gestureStream;
  static CameraYoloService get camera => _camera;

  static GestureSessionState _state = GestureSessionState.disconnected;
  static StreamSubscription<Map<String, dynamic>>? _predictionSub;
  static StreamSubscription<String>? _cameraGestureSub;
  static StreamSubscription<String>? _socketStatusSub;
  static StreamSubscription<String>? _socketErrorSub;
  static bool _busy = false;
  static bool _captureActive = false;
  static String? _pendingGesture;
  static int _connectionRefs = 0;

  static GestureSessionState get state => _state;
  static bool get isConnected => _state != GestureSessionState.disconnected;
  static bool get isCapturing => _captureActive;
  static String? get pendingGesture => _pendingGesture;

  static void _setState(GestureSessionState next, String status) {
    _state = next;
    _stateController.add(next);
    _statusController.add(status);
  }

  static Future<bool> connect({
    bool showCameraPreview = false,
    bool useFrontCamera = true,
  }) async {
    if (_state == GestureSessionState.connecting) {
      return false;
    }

    if (isConnected) {
      _connectionRefs++;
      if (showCameraPreview) {
        await _camera.start(useFrontCamera: useFrontCamera, startPreview: true);
      }
      return true;
    }

    _setState(GestureSessionState.connecting, 'Connecting...');

    final deviceId = await AuthService.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      _setState(GestureSessionState.disconnected, 'No device linked. Set device in profile.');
      return false;
    }

    final socketOk = await PredictSocketService.connect(deviceId: deviceId);
    if (!socketOk) {
      _setState(GestureSessionState.disconnected, 'Could not connect to prediction socket');
      return false;
    }

    final cameraOk = await _camera.start(
      useFrontCamera: useFrontCamera,
      startPreview: showCameraPreview,
    );
    if (!cameraOk) {
      await PredictSocketService.disconnect();
      _setState(GestureSessionState.disconnected, 'Could not start camera');
      return false;
    }

    await _predictionSub?.cancel();
    await _cameraGestureSub?.cancel();
    await _socketStatusSub?.cancel();
    await _socketErrorSub?.cancel();

    _predictionSub = PredictSocketService.predictionStream.listen(_onPrediction);
    _cameraGestureSub = _camera.gestureStream.listen(_onGestureDetected);
    _socketStatusSub = PredictSocketService.statusStream.listen((status) {
      if (_state != GestureSessionState.speaking) {
        _statusController.add(status);
      }
    });
    _socketErrorSub = PredictSocketService.errorStream.listen((error) {
      _busy = false;
      if (isConnected) {
        _setState(
          _captureActive ? GestureSessionState.capturing : GestureSessionState.connected,
          error,
        );
      } else {
        _statusController.add(error);
      }
    });

    _connectionRefs = 1;
    _setState(
      GestureSessionState.connected,
      showCameraPreview
          ? 'Connected · Camera active'
          : 'Connected · Front camera in background',
    );
    return true;
  }

  static Future<void> disconnect({bool force = false}) async {
    if (!force && _connectionRefs > 1) {
      _connectionRefs--;
      return;
    }

    _connectionRefs = 0;
    _captureActive = false;
    _camera.setInferenceEnabled(false);
    _pendingGesture = null;
    _pendingGestureController.add(null);

    await _predictionSub?.cancel();
    await _cameraGestureSub?.cancel();
    await _socketStatusSub?.cancel();
    await _socketErrorSub?.cancel();
    _predictionSub = null;
    _cameraGestureSub = null;
    _socketStatusSub = null;
    _socketErrorSub = null;

    await _camera.stop();
    await PredictSocketService.disconnect();
    await SpeechService.stop();
    _busy = false;
    _setState(GestureSessionState.disconnected, 'Disconnected');
  }

  static Future<bool> flipCamera() async {
    if (!isConnected) return false;
    return _camera.flipCamera();
  }

  static void startCapture() {
    if (!isConnected) return;
    _captureActive = true;
    _pendingGesture = null;
    _pendingGestureController.add(null);
    _camera.setInferenceEnabled(true);
    _setState(GestureSessionState.capturing, 'Capture started · perform gesture');
  }

  static Future<void> selectGesture(String gesture) async {
    if (!isConnected) return;

    final normalized = gesture.trim().toUpperCase();
    if (normalized.isEmpty) return;

    if (_captureActive) {
      _pendingGesture = normalized;
      _pendingGestureController.add(normalized);
      _setState(
        GestureSessionState.capturing,
        'Gesture selected: $normalized · press End to send',
      );
      return;
    }

    await _camera.submitGesture(normalized, force: true);
  }

  static Future<void> endCapture() async {
    if (!isConnected || !_captureActive) return;

    _captureActive = false;
    _camera.setInferenceEnabled(false);

    if (_pendingGesture == null || _pendingGesture!.isEmpty) {
      _setState(GestureSessionState.connected, 'No gesture captured · try again');
      return;
    }

    await _sendGestureToDevice(_pendingGesture!);
    _pendingGesture = null;
    _pendingGestureController.add(null);
  }

  static Future<void> _onGestureDetected(String gesture) async {
    if (!isConnected) return;

    if (_captureActive) {
      _pendingGesture = gesture;
      _pendingGestureController.add(gesture);
      _setState(
        GestureSessionState.capturing,
        'Detected $gesture · press End to send',
      );
      return;
    }

    if (_busy) return;
    await _sendGestureToDevice(gesture);
  }

  static Future<void> _sendGestureToDevice(String gesture) async {
    if (_busy) return;

    _busy = true;
    _setState(GestureSessionState.processing, 'Sending $gesture to gesture device...');

    final deviceId = await AuthService.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      _busy = false;
      _setState(GestureSessionState.connected, 'No device linked');
      return;
    }

    final result = await GestureDeviceApiService.submitGesture(
      gesture: gesture,
      deviceId: deviceId,
    );

    if (result['success'] != true) {
      _busy = false;
      _setState(
        GestureSessionState.connected,
        result['message']?.toString() ?? 'Gesture device request failed',
      );
      return;
    }

    _setState(GestureSessionState.connected, 'Waiting for backend prediction...');
  }

  static Future<void> _onPrediction(Map<String, dynamic> payload) async {
    final text = payload['text']?.toString() ??
        payload['character']?.toString() ??
        '—';

    _lastPredictionController.add(text);
    _setState(GestureSessionState.speaking, 'Speaking: $text');

    final phrase = GestureSpeechMapper.phraseFor(text);
    await SpeechService.speak(phrase);

    _busy = false;
    if (isConnected) {
      _setState(
        _captureActive ? GestureSessionState.capturing : GestureSessionState.connected,
        'Listening for gestures...',
      );
    }
  }
}
