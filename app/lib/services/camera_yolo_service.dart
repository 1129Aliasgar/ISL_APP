import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Camera + YOLO TFLite gesture classifier.
/// Model input: [1, 224, 224, 3] float32 — output: [1, 5] float32.
class CameraYoloService {
  static const _modelAsset = 'assets/model/yolo.tflite';
  static const _inputSize = 224;
  static const _confidenceThreshold = 0.35;

  static const List<String> _labels = ['A', 'B', 'C', 'HELLO', 'HI'];

  CameraController? _controller;
  bool _running = false;
  bool _useFrontCamera = true;
  bool _inferenceEnabled = false;
  bool _isProcessingFrame = false;
  int _frameCounter = 0;

  String? _lastGesture;
  DateTime? _lastGestureAt;

  Interpreter? _interpreter;
  late List<List<List<List<double>>>> _input;
  late List<List<double>> _output;

  final StreamController<String> _gestureController =
      StreamController<String>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  Stream<String> get gestureStream => _gestureController.stream;
  Stream<String> get statusStream => _statusController.stream;
  CameraController? get controller => _controller;
  bool get isRunning => _running;
  bool get isFrontCamera => _useFrontCamera;
  bool get isModelLoaded => _interpreter != null;

  void setInferenceEnabled(bool enabled) {
    _inferenceEnabled = enabled;
    if (enabled) {
      _statusController.add('YOLO inference active');
    }
  }

  void _initBuffers() {
    _input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (_) => List.generate(
          _inputSize,
          (_) => List<double>.filled(3, 0.0),
        ),
      ),
    );
    _output = List.generate(1, (_) => List<double>.filled(_labels.length, 0.0));
  }

  Future<bool> _loadModel() async {
    if (_interpreter != null) return true;

    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelAsset, options: options);
      _initBuffers();
      _statusController.add('YOLO model loaded');
      return true;
    } catch (e) {
      _statusController.add('YOLO model load failed: $e');
      return false;
    }
  }

  Future<bool> start({
    bool useFrontCamera = true,
    bool startPreview = true,
  }) async {
    if (_running && _useFrontCamera == useFrontCamera) {
      return true;
    }

    if (_running) {
      await stop();
    }

    _useFrontCamera = useFrontCamera;

    try {
      final modelOk = await _loadModel();
      if (!modelOk) return false;

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
        startPreview ? 'Camera active' : 'Front camera active (background)',
      );

      await _controller!.startImageStream(_onCameraImage);
      return true;
    } catch (e) {
      _statusController.add('Camera error: $e');
      return false;
    }
  }

  Future<bool> flipCamera() async {
    return start(useFrontCamera: !_useFrontCamera, startPreview: true);
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (!_inferenceEnabled || _interpreter == null || _isProcessingFrame) {
      return;
    }

    _frameCounter++;
    if (_frameCounter % 4 != 0) return;

    _isProcessingFrame = true;
    try {
      final label = _runInference(image);
      if (label != null && label.isNotEmpty) {
        await submitGesture(label);
      }
    } catch (e) {
      if (kDebugMode) {
        _statusController.add('Inference error: $e');
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  String? _runInference(CameraImage cameraImage) {
    final rgb = _cameraImageToRgb(cameraImage, mirror: _useFrontCamera);
    if (rgb == null) return null;

    final resized = img.copyResize(rgb, width: _inputSize, height: _inputSize);

    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        _input[0][y][x][0] = pixel.r / 255.0;
        _input[0][y][x][1] = pixel.g / 255.0;
        _input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    _interpreter!.run(_input, _output);

    final scores = _output[0];
    var bestIdx = 0;
    var bestScore = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIdx = i;
      }
    }

    if (bestScore < _confidenceThreshold) return null;
    return _labels[bestIdx];
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
    _inferenceEnabled = false;

    if (_controller != null) {
      try {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
      } catch (_) {}
      await _controller!.dispose();
    }

    _controller = null;
    _interpreter?.close();
    _interpreter = null;
    _running = false;
    _lastGesture = null;
    _lastGestureAt = null;
    _frameCounter = 0;
    _statusController.add('Camera stopped');
  }
}

img.Image? _cameraImageToRgb(CameraImage image, {required bool mirror}) {
  if (image.format.group != ImageFormatGroup.yuv420) {
    return null;
  }

  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final out = img.Image(width: width, height: height);

  for (var h = 0; h < height; h++) {
    for (var w = 0; w < width; w++) {
      final x = mirror ? width - w - 1 : w;
      final yIndex = h * yPlane.bytesPerRow + x;
      final uvIndex = (h ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!;

      final y = yPlane.bytes[yIndex];
      final u = uPlane.bytes[uvIndex];
      final v = vPlane.bytes[uvIndex];

      final r = (y + 1.402 * (v - 128)).clamp(0, 255).toInt();
      final g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).clamp(0, 255).toInt();
      final b = (y + 1.772 * (u - 128)).clamp(0, 255).toInt();

      out.setPixelRgb(w, h, r, g, b);
    }
  }

  return out;
}
