import 'dart:async';
import 'package:flutter/material.dart';
import 'package:g_one/screens/account_screen.dart';
import 'package:g_one/screens/game_controller_screen.dart';
import 'package:g_one/screens/settings_screen.dart';
import 'package:g_one/screens/translate_screen.dart';
import 'package:g_one/screens/video_calling_screen.dart';
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/services/gesture_session_service.dart';
import 'package:g_one/services/speech_service.dart';
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
  String _statusMessage = 'Disconnected';
  String _lastPrediction = '—';
  String? _pendingGesture;
  String? _deviceId;
  GestureSessionState _sessionState = GestureSessionState.disconnected;

  StreamSubscription<bool>? _speakingSub;
  StreamSubscription<GestureSessionState>? _stateSub;
  StreamSubscription<String>? _statusSub;
  StreamSubscription<String>? _predictionSub;
  StreamSubscription<String?>? _pendingSub;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    await _refreshDeviceId();
    _speakingSub = SpeechService.speakingStream.listen((speaking) {
      if (!mounted) return;
      setState(() => _isSpeaking = speaking);
    });
    _stateSub = GestureSessionService.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _sessionState = state);
    });
    _statusSub = GestureSessionService.statusStream.listen((status) {
      if (!mounted) return;
      setState(() => _statusMessage = status);
    });
    _predictionSub = GestureSessionService.lastPredictionStream.listen((text) {
      if (!mounted) return;
      setState(() => _lastPrediction = text);
    });
    _pendingSub = GestureSessionService.pendingGestureStream.listen((gesture) {
      if (!mounted) return;
      setState(() => _pendingGesture = gesture);
    });
  }

  Future<void> _refreshDeviceId() async {
    final value = await AuthService.getDeviceId();
    if (!mounted) return;
    setState(() => _deviceId = value);
  }

  Future<void> _toggleConnect() async {
    if (GestureSessionService.isConnected) {
      await GestureSessionService.disconnect(force: true);
      return;
    }

    setState(() => _statusMessage = 'Connecting...');
    final ok = await GestureSessionService.connect(
      showCameraPreview: false,
      useFrontCamera: true,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _statusMessage = 'Connection failed');
    }
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
    _speakingSub?.cancel();
    _stateSub?.cancel();
    _statusSub?.cancel();
    _predictionSub?.cancel();
    _pendingSub?.cancel();
    super.dispose();
  }

  Widget _buildHomeTab(BuildContext context) {
    final isConnected = GestureSessionService.isConnected;
    final isConnecting = _sessionState == GestureSessionState.connecting;
    final isCapturing = GestureSessionService.isCapturing;

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
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: isConnecting ? null : _toggleConnect,
            icon: Icon(isConnected ? Icons.link_off_rounded : Icons.link_rounded),
            label: Text(isConnected ? 'Disconnect' : 'Connect'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(200, 48),
              backgroundColor: isConnected ? Colors.redAccent : const Color(0xFF7B61FF),
            ),
          ),
        ),
        if (isConnected) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isCapturing ? null : GestureSessionService.startCapture,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isCapturing ? GestureSessionService.endCapture : null,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('End'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4FD8),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        SectionCard(
          title: 'Live Translation',
          subtitle: _deviceId == null ? 'No device linked' : 'Device: $_deviceId',
        ),
        if (_pendingGesture != null)
          SectionCard(
            title: 'Pending Gesture',
            subtitle: 'Press End to send to gesture device',
            child: Text(
              _pendingGesture!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF00E5FF),
                  ),
            ),
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
              : Icon(
                  isConnected ? Icons.sensors : Icons.sensors_off,
                  color: isConnected ? const Color(0xFF00E5FF) : Colors.white54,
                ),
        ),
        if (isConnected)
          SectionCard(
            title: 'Quick Gestures',
            subtitle: isCapturing
                ? 'Tap a gesture, then press End'
                : 'Press Start first, or tap to send immediately',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['A', 'B', 'C', 'HELLO', 'HI'].map((gesture) {
                return OutlinedButton(
                  onPressed: () => GestureSessionService.selectGesture(gesture),
                  child: Text(gesture),
                );
              }).toList(),
            ),
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
