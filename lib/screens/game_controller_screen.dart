import 'package:flutter/material.dart';
import 'package:g_one/widgets/section_card.dart';

class GameControllerScreen extends StatefulWidget {
  const GameControllerScreen({super.key});

  @override
  State<GameControllerScreen> createState() => _GameControllerScreenState();
}

class _GameControllerScreenState extends State<GameControllerScreen> {
  String _currentGesture = 'None';
  String _mappedAction = 'None';

  // Gesture to game action mapping
  final Map<String, String> _gestureMap = {
    'A': 'Jump',
    'B': 'Crouch',
    'C': 'Move Left',
    'D': 'Move Right',
    'Fist': 'Punch',
    'Open Hand': 'Defend',
    'Thumbs Up': 'Confirm',
    'Thumbs Down': 'Cancel',
  };

  void _onGestureDetected(String gesture) {
    setState(() {
      _currentGesture = gesture;
      _mappedAction = _gestureMap[gesture] ?? 'Unknown Action';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Controller')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Current Gesture',
            subtitle: 'Detected gesture from ISL',
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
            title: 'Mapped Action',
            subtitle: 'Game control action',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _mappedAction,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF00E5FF),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SectionCard(
            title: 'Gesture Mapping',
            subtitle: 'ISL gestures mapped to game controls',
            child: Column(
              children: _gestureMap.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Icon(Icons.arrow_forward, size: 16),
                      Text(
                        entry.value,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF00E5FF),
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SectionCard(
            title: 'Note',
            subtitle: 'Gesture detection will be integrated with Bluetooth glove sensors',
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Simulate gesture detection for demo
              final gestures = _gestureMap.keys.toList();
              final randomGesture = gestures[DateTime.now().millisecond % gestures.length];
              _onGestureDetected(randomGesture);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Simulate Gesture (Demo)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

