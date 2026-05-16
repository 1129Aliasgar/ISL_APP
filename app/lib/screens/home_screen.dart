import 'dart:async';
import 'package:flutter/material.dart';
import 'package:g_one/screens/account_screen.dart';
import 'package:g_one/screens/game_controller_screen.dart';
import 'package:g_one/screens/settings_screen.dart';
import 'package:g_one/screens/translate_screen.dart';
import 'package:g_one/screens/video_calling_screen.dart';
import 'package:g_one/services/api_service.dart';
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/widgets/section_card.dart';
import 'package:g_one/widgets/voice_assistant_orb.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  bool _isSpeaking = false;
  String _statusMessage = 'Listening for glove gestures...';
  String _lastPrediction = '—';
  String? _deviceId;
  String? _lastPredictionId;
  Timer? _pollTimer;
  StreamSubscription<bool>? _speakingSub;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    await _refreshDeviceId();
    _speakingSub = ApiService.speakingStream.listen((speaking) {
      if (!mounted) return;
      setState(() => _isSpeaking = speaking);
    });
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollLatestPrediction());
    _pollLatestPrediction();
  }

  Future<void> _pollLatestPrediction() async {
    final deviceId = _deviceId;
    if (deviceId == null || deviceId.isEmpty) return;

    final result = await ApiService.fetchLatestPrediction(deviceId);
    if (!mounted) return;

    if (result['notFound'] == true) {
      setState(() {
        _statusMessage = 'Waiting for first gesture from glove...';
      });
      return;
    }

    if (result['success'] != true) {
      setState(() {
        _statusMessage = result['message']?.toString() ?? 'Could not fetch prediction';
      });
      return;
    }

    final id = result['id']?.toString();
    if (id == null || id == _lastPredictionId) return;

    final prediction = result['prediction'] as Map<String, dynamic>?;
    final character = prediction?['character']?.toString() ?? '—';
    final audioUrl = result['audioUrl'] as String?;

    setState(() {
      _lastPredictionId = id;
      _lastPrediction = character;
      _statusMessage = 'New prediction received';
    });

    if (audioUrl != null && audioUrl.isNotEmpty) {
      final played = await ApiService.playAudioFromUrl(audioUrl);
      if (!mounted) return;
      setState(() {
        _statusMessage = played ? 'Playing: $character' : 'Prediction ready (audio failed)';
      });
    }
  }

  Future<void> _refreshDeviceId() async {
    final value = await AuthService.getDeviceId();
    if (!mounted) return;
    setState(() => _deviceId = value);
  }

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
    await _refreshDeviceId();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _speakingSub?.cancel();
    super.dispose();
  }

  Widget _buildHomeTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: VoiceAssistantOrb(
            isSpeaking: _isSpeaking,
            size: 240,
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          title: 'Live Translation',
          subtitle: _deviceId == null ? 'No device linked' : 'Device: $_deviceId',
        ),
        SectionCard(
          title: 'Recognized Gesture',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _lastPrediction,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFFFF4FD8),
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SectionCard(
          title: 'Status',
          subtitle: _statusMessage,
          trailing: _isSpeaking
              ? const Icon(Icons.graphic_eq, color: Color(0xFFFF4FD8))
              : const Icon(Icons.hearing_outlined),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(context),
      const GameControllerScreen(compact: true),
      const VideoCallingScreen(compact: true),
      const TranslateScreen(compact: true),
    ];

    final avatarText = ((_deviceId ?? 'U').isNotEmpty ? (_deviceId ?? 'U')[0] : 'U').toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0614),
      appBar: AppBar(
        title: const Text('G-ONE'),
        leading: IconButton(
          onPressed: _openProfile,
          icon: CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF7B61FF),
            child: Text(
              avatarText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (value) => setState(() => _selectedTab = value),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF120A1F),
        selectedItemColor: const Color(0xFFFF4FD8),
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports_rounded), label: 'Gaming'),
          BottomNavigationBarItem(icon: Icon(Icons.video_call_rounded), label: 'Video'),
          BottomNavigationBarItem(icon: Icon(Icons.translate_rounded), label: 'Translation'),
        ],
      ),
    );
  }
}
