import 'package:flutter/material.dart';
import 'package:g_one/screens/account_screen.dart';
import 'package:g_one/screens/game_controller_screen.dart';
import 'package:g_one/screens/settings_screen.dart';
import 'package:g_one/screens/translate_screen.dart';
import 'package:g_one/screens/video_calling_screen.dart';
import 'package:g_one/services/api_service.dart';
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/widgets/section_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  bool _isLoading = false;
  bool _isPlaying = false;
  String _statusMessage = 'Waiting for glove gesture...';
  String _lastPrediction = '—';
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _refreshDeviceId();
  }

  Future<void> _refreshDeviceId() async {
    final value = await AuthService.getDeviceId();
    if (!mounted) return;
    setState(() => _deviceId = value);
  }

  Future<void> _sendDemoGesture() async {
    final deviceId = _deviceId;
    if (deviceId == null || deviceId.isEmpty) return;
    setState(() {
      _isLoading = true;
      _statusMessage = 'Processing glove sequence...';
    });

    try {
      final result = await ApiService.predictFromSensors(
        deviceId: deviceId,
        sensors: const {
          "flex": [0, 189, 0, 16, 0],
          "accel": [70, 96, 1631],
          "gyro": [13, 12, 4]
        },
        end: true,
      );
      setState(() {
        _lastPrediction = (result['prediction']?['character'] ?? '—').toString();
        _statusMessage = result['success'] == true
            ? 'Prediction received and audio played'
            : 'Error: ${result['message'] ?? 'Unknown error'}';
        _isPlaying = result['success'] == true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
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

  Widget _buildHomeTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Audio Wave',
          subtitle: _isPlaying ? 'Playing generated speech' : 'Ready',
          child: SizedBox(
            height: 64,
            child: _WaveVisualizer(isActive: _isPlaying || _isLoading),
          ),
        ),
        SectionCard(
          title: 'Device',
          subtitle: _deviceId == null ? 'No device found' : 'Connected device: $_deviceId',
        ),
        SectionCard(
          title: 'Translation',
          subtitle: 'Latest prediction output',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _lastPrediction,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SectionCard(
          title: 'Status',
          subtitle: _statusMessage,
          trailing: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.info_outline),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendDemoGesture,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Trigger Prediction (Demo)'),
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
      appBar: AppBar(
        title: const Text('Live Translation'),
        leading: IconButton(
          onPressed: _openProfile,
          icon: CircleAvatar(
            radius: 14,
            child: Text(avatarText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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

class _WaveVisualizer extends StatefulWidget {
  final bool isActive;
  const _WaveVisualizer({required this.isActive});

  @override
  State<_WaveVisualizer> createState() => _WaveVisualizerState();
}

class _WaveVisualizerState extends State<_WaveVisualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.secondary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(24, (index) {
            final phase = (_controller.value + index * 0.08) % 1.0;
            final amp = widget.isActive ? (0.3 + phase * 0.7) : 0.15;
            final h = 10 + amp * 46;
            return Container(
              width: 4,
              height: h,
              decoration: BoxDecoration(
                color: base.withOpacity(widget.isActive ? 0.9 : 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        );
      },
    );
  }
}


