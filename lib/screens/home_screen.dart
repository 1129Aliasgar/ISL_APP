import 'package:flutter/material.dart';
import 'package:g_one/utils/constants.dart';
import 'package:g_one/services/api_service.dart';
import 'package:g_one/services/settings_service.dart';
import 'package:g_one/widgets/section_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = 'Enter text to convert to speech';

  Future<void> _convertToSpeech() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter some text';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Processing...';
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
      
      setState(() {
        _statusMessage = result['success'] == true
            ? 'Speech generated successfully!'
            : 'Error: ${result['message'] ?? 'Unknown error'}';
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
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Translation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeSettings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Text Input',
            subtitle: 'Enter text to convert to speech using NLP',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Enter your text here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _convertToSpeech,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Convert to Speech'),
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
          const SizedBox(height: 16),
          SectionCard(
            title: 'Game Controller',
            subtitle: 'Map gestures to game controls',
            trailing: const Icon(Icons.sports_esports, color: Colors.white70),
            onTap: () => Navigator.pushNamed(context, AppConstants.routeGameController),
          ),
          SectionCard(
            title: 'Video Calling',
            subtitle: 'Convert gestures to speech for calls',
            trailing: const Icon(Icons.video_call, color: Colors.white70),
            onTap: () => Navigator.pushNamed(context, AppConstants.routeVideoCalling),
          ),
        ],
      ),
    );
  }
}


