import 'dart:async';
import 'package:camera/camera.dart';

/// Camera capture service. YOLO TFLite inference can be plugged into [onFrame].
/// Place model at assets/models/yolo.tflite when available.
class CameraYoloService {
  CameraController? _controller;
  Timer? _frameTimer;
  bool _running = false;
  String? _lastGesture;
  DateTime? _lastGestureAt;

  final StreamController<String> _gestureController =
      StreamController<String>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  Stream<String> get gestureStream => _gestureController.stream;
  Stream<String> get statusStream => _statusController.stream;
  CameraController? get controller => _controller;
  bool get isRunning => _running;

  Future<bool> start({bool useFrontCamera = true}) async {
    if (_running) return true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _statusController.add('No camera found');
        return false;
      }

      final selected = cameras.firstWhere(
        (camera) => useFrontCamera
            ? camera.lensDirection == CameraLensDirection.front
            : camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      _running = true;
      _statusController.add('Camera active');

      _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _onFrameTick();
      });

      return true;
    } catch (e) {
      _statusController.add('Camera error: $e');
      return false;
    }
  }

  void _onFrameTick() {
    // Hook for YOLO TFLite inference on camera frames.
    // Until yolo.tflite is bundled, gestures are submitted via [submitGesture].
  }

  /// Manual or YOLO-backed gesture submission with debounce.
  Future<void> submitGesture(String gesture, {Duration debounce = const Duration(milliseconds: 1200)}) async {
    final normalized = gesture.trim().toUpperCase();
    if (normalized.isEmpty) return;

    final now = DateTime.now();
    if (_lastGesture == normalized &&
        _lastGestureAt != null &&
        now.difference(_lastGestureAt!) < debounce) {
      return;
    }

    _lastGesture = normalized;
    _lastGestureAt = now;
    _gestureController.add(normalized);
  }

  Future<void> stop() async {
    _frameTimer?.cancel();
    _frameTimer = null;
    await _controller?.dispose();
    _controller = null;
    _running = false;
    _lastGesture = null;
    _lastGestureAt = null;
    _statusController.add('Camera stopped');
  }

  void dispose() {
    stop();
    _gestureController.close();
    _statusController.close();
  }
}
