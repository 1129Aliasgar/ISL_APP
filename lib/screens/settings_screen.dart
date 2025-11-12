import 'package:flutter/material.dart';
import 'package:g_one/utils/languages.dart';
import 'package:g_one/services/settings_service.dart';
import 'package:g_one/widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double pitch = SettingsService.defaultPitch;
  double volume = SettingsService.defaultVolume;
  double speed = SettingsService.defaultSpeed;
  String selectedLanguage = SettingsService.defaultLanguage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getSettings();
    setState(() {
      pitch = settings['pitch'] as double;
      volume = settings['volume'] as double;
      speed = settings['speed'] as double;
      selectedLanguage = settings['language'] as String;
      _isLoading = false;
    });
  }

  Future<void> _updateLanguage(String? value) async {
    if (value != null) {
      setState(() => selectedLanguage = value);
      await SettingsService.saveLanguage(value);
    }
  }

  Future<void> _updatePitch(double value) async {
    setState(() => pitch = value);
    await SettingsService.savePitch(value);
  }

  Future<void> _updateVolume(double value) async {
    setState(() => volume = value);
    await SettingsService.saveVolume(value);
  }

  Future<void> _updateSpeed(double value) async {
    setState(() => speed = value);
    await SettingsService.saveSpeed(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Output Language',
            subtitle: 'Select language for translation output',
            child: DropdownButtonFormField<String>(
              value: selectedLanguage,
              isExpanded: true,
              items: [
                for (final lang in LanguagesData.supported)
                  DropdownMenuItem(
                    value: lang.code,
                    child: Text(lang.name),
                  )
              ],
              onChanged: _updateLanguage,
            ),
          ),
          SectionCard(
            title: 'Speech Pitch',
            subtitle: 'Adjust the pitch of spoken output',
            child: Column(
              children: [
                Slider(
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  value: pitch,
                  label: pitch.toStringAsFixed(2),
                  onChanged: _updatePitch,
                ),
                Text(
                  'Current: ${pitch.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Speech Volume',
            subtitle: 'Adjust the volume of spoken output',
            child: Column(
              children: [
                Slider(
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  value: volume,
                  label: '${(volume * 100).round()}%',
                  onChanged: _updateVolume,
                ),
                Text(
                  'Current: ${(volume * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SectionCard(
            title: 'Speech Speed',
            subtitle: 'Adjust the speed of spoken output',
            child: Column(
              children: [
                Slider(
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  value: speed,
                  label: speed.toStringAsFixed(2),
                  onChanged: _updateSpeed,
                ),
                Text(
                  'Current: ${speed.toStringAsFixed(2)}x',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SectionCard(
            title: 'Theme',
            subtitle: 'Dark theme is enabled by default',
            trailing: Icon(Icons.dark_mode),
          ),
        ],
      ),
    );
  }
}


