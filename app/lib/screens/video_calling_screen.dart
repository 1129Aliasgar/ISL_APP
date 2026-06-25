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
  bool _videoStartedSession = false;

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
    GestureSessionService.pendingGestureStream.listen((gesture) {
      if (!mounted || !_isCallActive || gesture == null) return;
      setState(() => _currentGesture = gesture);
    });
  }

  Future<void> _startCall() async {
    setState(() {
      _isCallActive = true;
      _statusMessage = 'Starting camera...';
    });

    if (!GestureSessionService.isConnected) {
      _videoStartedSession = true;
      final ok = await GestureSessionService.connect(
        showCameraPreview: true,
        useFrontCamera: true,
      );
      if (!ok && mounted) {
        setState(() {
          _isCallActive = false;
          _videoStartedSession = false;
          _statusMessage = 'Could not start call session';
        });
        return;
      }
    } else {
      await GestureSessionService.camera.start(
        useFrontCamera: true,
        startPreview: true,
      );
    }

    if (mounted) {
      setState(() => _statusMessage = 'Call active · Start → gesture → End');
    }
  }

  Future<void> _endCall() async {
    if (_videoStartedSession) {
      await GestureSessionService.disconnect(force: true);
      _videoStartedSession = false;
    } else {
      await GestureSessionService.disconnect();
    }

    if (!mounted) return;
    setState(() {
      _isCallActive = false;
      _currentGesture = 'None';
      _convertedSpeech = '—';
      _statusMessage = 'Call not active';
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Video Call',
          subtitle: _statusMessage,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isCallActive)
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(64, 64),
                  ),
                  onPressed: _endCall,
                  icon: const Icon(Icons.call_end_rounded, size: 30),
                )
              else
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF0A0614),
                    minimumSize: const Size(64, 64),
                  ),
                  onPressed: _startCall,
                  icon: const Icon(Icons.videocam_rounded, size: 30),
                ),
            ],
          ),
        ),
        if (_isCallActive) ...[
          SectionCard(
            title: 'Camera',
            subtitle: 'YOLO detects gestures from this feed',
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                _buildCameraPreview(),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await GestureSessionService.flipCamera();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.cameraswitch_rounded),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: GestureSessionService.startCapture,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: GestureSessionService.endCapture,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('End'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4FD8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SectionCard(
          title: 'Current Gesture',
          subtitle: 'Detected or selected gesture',
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
          title: 'Prediction',
          subtitle: 'Spoken on device after backend responds',
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
        if (_isCallActive)
          SectionCard(
            title: 'Quick Gestures',
            subtitle: 'Start → tap gesture → End',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _gestureToText.keys.map((gesture) {
                return ElevatedButton(
                  onPressed: () => GestureSessionService.selectGesture(gesture),
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
}
