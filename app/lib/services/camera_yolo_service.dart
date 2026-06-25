import 'dart:async';
import 'package:camera/camera.dart';

/// Camera + gesture capture. YOLO hooks into [_onFrameTick] when model is bundled.
class CameraYoloService {
  CameraController? _controller;
  Timer? _frameTimer;
  bool _running = false;
  bool _useFrontCamera = true;
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
  bool get isFrontCamera => _useFrontCamera;

  Future<bool> start({
    bool useFrontCamera = true,
    bool startPreview = true,
  }) async {
    if (_running && _useFrontCamera == useFrontCamera) return true;

    if (_running) {
      await stop();
    }

    _useFrontCamera = useFrontCamera;

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
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      _running = true;
      _statusController.add(
        startPreview
            ? 'Camera active'
            : 'Front camera active (background)',
      );

      _frameTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _onFrameTick();
      });

      return true;
    } catch (e) {
      _statusController.add('Camera error: $e');
      return false;
    }
  }

  Future<bool> flipCamera() async {
    return start(useFrontCamera: !_useFrontCamera, startPreview: true);
  }

  void _onFrameTick() {
    // YOLO TFLite inference on frames when model is available.
  }

  Future<void> submitGesture(
    String gesture, {
    Duration debounce = const Duration(milliseconds: 1200),
    bool force = false,
  }) async {
    final normalized = gesture.trim().toUpperCase();
    if (normalized.isEmpty) return;

    final now = DateTime.now();
    if (!force &&
        _lastGesture == normalized &&
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
}
