import 'package:flutter/material.dart';
import 'package:g_one/utils/constants.dart';
import 'package:g_one/services/api_service.dart';
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/widgets/section_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _statusMessage = 'Waiting for glove gesture...';
  String _lastPrediction = '—';
  bool _isPlaying = false;
  String? _deviceId;

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
        sensors: {
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    AuthService.getDeviceId().then((value) => setState(() => _deviceId = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Translation'),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeSettings),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('G-ONE Menu')),
            ListTile(
              title: const Text('Account'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.routeAccount);
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: () async {
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, AppConstants.routeLogin);
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Device',
            subtitle: _deviceId == null ? 'No device found' : 'Connected device: $_deviceId',
          ),
          SectionCard(
            title: 'Prediction',
            subtitle: 'Latest glove output',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _lastPrediction,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                SizedBox(height: 48, child: _FakeWave(isActive: _isPlaying || _isLoading)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendDemoGesture,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simulate Gesture Prediction'),
                  ),
                ),
              ],
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
        ],
      ),
    );
  }
}

class _FakeWave extends StatelessWidget {
  final bool isActive;
  const _FakeWave({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.secondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(18, (index) {
        final h = isActive ? (12.0 + (index % 6) * 6.0) : 10.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: 6,
          height: h,
          decoration: BoxDecoration(
            color: base.withOpacity(0.85),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}


