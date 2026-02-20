import 'package:flutter/material.dart';
import 'package:g_one/services/api_service.dart';
import 'package:g_one/services/settings_service.dart';
import 'package:g_one/widgets/section_card.dart';

class VideoCallingScreen extends StatefulWidget {
  const VideoCallingScreen({super.key});

  @override
  State<VideoCallingScreen> createState() => _VideoCallingScreenState();
}

class _VideoCallingScreenState extends State<VideoCallingScreen> {
  String _currentGesture = 'None';
  String _convertedSpeech = '—';
  bool _isProcessing = false;
  bool _isCallActive = false;

  // Simulated gesture to text mapping
  final Map<String, String> _gestureToText = {
    'Hello': 'Hello, how are you?',
    'Thank You': 'Thank you very much',
    'Yes': 'Yes, I agree',
    'No': 'No, I disagree',
    'Help': 'I need help',
    'Good': 'That is good',
    'Bad': 'That is bad',
  };

  Future<void> _convertGestureToSpeech(String gesture) async {
    final text = _gestureToText[gesture];
    if (text == null) return;

    setState(() {
      _isProcessing = true;
      _convertedSpeech = 'Processing...';
    });

    try {
      // Get current settings
      final settings = await SettingsService.getSettings();
      
      final result = await ApiService.speak(
        text: text,
        language: settings['language'] as String,
        pitch: settings['pitch'] as double,
        volume: settings['volume'] as double,
        speed: settings['speed'] as double,
      );
      
      if (result['success'] == true) {
        setState(() {
          _convertedSpeech = text;
        });
      } else {
        setState(() {
          _convertedSpeech = 'Error: ${result['message']}';
        });
      }
    } catch (e) {
      setState(() {
        _convertedSpeech = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _simulateGesture(String gesture) {
    setState(() {
      _currentGesture = gesture;
    });
    if (_isCallActive) {
      _convertGestureToSpeech(gesture);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Calling')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Call Status',
            subtitle: _isCallActive ? 'Call in progress' : 'Call not active',
            trailing: Switch(
              value: _isCallActive,
              onChanged: (value) {
                setState(() {
                  _isCallActive = value;
                  if (!value) {
                    _currentGesture = 'None';
                    _convertedSpeech = '—';
                  }
                });
              },
            ),
          ),
          SectionCard(
            title: 'Current Gesture',
            subtitle: 'ISL gesture detected',
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
            subtitle: 'Text converted from gesture (sent to other person)',
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
          if (_isProcessing)
            const SectionCard(
              title: 'Processing',
              subtitle: 'Converting gesture to speech...',
              trailing: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          SectionCard(
            title: 'Quick Gestures',
            subtitle: 'Tap to simulate gesture (for demo)',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _gestureToText.keys.map((gesture) {
                return ElevatedButton(
                  onPressed: _isCallActive ? () => _simulateGesture(gesture) : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(gesture),
                );
              }).toList(),
            ),
          ),
          const SectionCard(
            title: 'Note',
            subtitle: 'In production, gestures will be detected from Bluetooth glove in real-time',
          ),
        ],
      ),
    );
  }
}

