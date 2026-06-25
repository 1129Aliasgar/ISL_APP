import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:g_one/services/gesture_session_service.dart';
import 'package:g_one/widgets/section_card.dart';

class VideoCallingScreen extends StatefulWidget {
  final bool compact;
  const VideoCallingScreen({super.key, this.compact = false});

  @override
  State<VideoCallingScreen> createState() => _VideoCallingScreenState();
}

class _VideoCallingScreenState extends State<VideoCallingScreen> {
  String _currentGesture = 'None';
  String _convertedSpeech = '—';
  String _statusMessage = 'Call not active';
  bool _isCallActive = false;

  final Map<String, String> _gestureToText = {
    'A': 'A',
    'B': 'B',
    'C': 'C',
    'HELLO': 'Hello',
    'HI': 'Hi',
  };

  @override
  void initState() {
    super.initState();
    GestureSessionService.lastPredictionStream.listen((text) {
      if (!mounted) return;
      setState(() {
        _convertedSpeech = text;
        _currentGesture = text;
      });
    });
    GestureSessionService.statusStream.listen((status) {
      if (!mounted || !_isCallActive) return;
      setState(() => _statusMessage = status);
    });
    GestureSessionService.cameraGestureStream.listen((gesture) {
      if (!mounted || !_isCallActive) return;
      setState(() => _currentGesture = gesture);
    });
  }

  Future<void> _toggleCall(bool value) async {
    if (value) {
      setState(() {
        _isCallActive = true;
        _statusMessage = 'Starting camera...';
      });

      if (!GestureSessionService.isConnected) {
        final ok = await GestureSessionService.connect(showCameraPreview: true);
        if (!ok && mounted) {
          setState(() {
            _isCallActive = false;
            _statusMessage = 'Could not start call session';
          });
          return;
        }
      }

      if (mounted) {
        setState(() => _statusMessage = 'Call active · make a gesture');
      }
      return;
    }

    await GestureSessionService.disconnect();
    if (!mounted) return;
    setState(() {
      _isCallActive = false;
      _currentGesture = 'None';
      _convertedSpeech = '—';
      _statusMessage = 'Call not active';
    });
  }

  Future<void> _simulateGesture(String gesture) async {
    if (!_isCallActive) return;
    setState(() {
      _currentGesture = gesture;
      _convertedSpeech = 'Processing...';
    });
    await GestureSessionService.submitGesture(gesture);
  }

  Widget _buildCameraPreview() {
    final controller = GestureSessionService.camera.controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Camera preview unavailable'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CameraPreview(controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Call Status',
          subtitle: _statusMessage,
          trailing: IconButton(
            icon: Icon(
              _isCallActive ? Icons.call_end : Icons.video_call,
              color: _isCallActive ? Colors.redAccent : const Color(0xFF00E5FF),
            ),
            onPressed: () => _toggleCall(!_isCallActive),
          ),
        ),
        if (_isCallActive)
          SectionCard(
            title: 'Camera',
            subtitle: 'YOLO will detect gestures from this feed',
            child: _buildCameraPreview(),
          ),
        SectionCard(
          title: 'Current Gesture',
          subtitle: 'Detected gesture label',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentGesture,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SectionCard(
          title: 'Converted Speech',
          subtitle: 'Backend prediction spoken on device',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _convertedSpeech,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF00E5FF),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SectionCard(
          title: 'Quick Gestures',
          subtitle: 'Tap to simulate YOLO output until model is added',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _gestureToText.keys.map((gesture) {
              return ElevatedButton(
                onPressed: _isCallActive ? () => _simulateGesture(gesture) : null,
                child: Text(gesture),
              );
            }).toList(),
          ),
        ),
      ],
    );

    if (widget.compact) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Video Calling')),
      body: content,
    );
  }
}
