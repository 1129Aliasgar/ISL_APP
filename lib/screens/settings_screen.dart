import 'package:flutter/material.dart';
import 'package:g_one/widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double pitch = 1.0; // 0.5 - 2.0
  double volume = 0.8; // 0.0 - 1.0

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Speech Pitch',
            subtitle: 'Adjust the pitch of spoken output',
            child: Slider(
              min: 0.5,
              max: 2.0,
              divisions: 15,
              value: pitch,
              label: pitch.toStringAsFixed(2),
              onChanged: (v) => setState(() => pitch = v),
            ),
          ),
          SectionCard(
            title: 'Speech Volume',
            subtitle: 'Adjust the volume of spoken output',
            child: Slider(
              min: 0.0,
              max: 1.0,
              divisions: 20,
              value: volume,
              label: (volume * 100).round().toString(),
              onChanged: (v) => setState(() => volume = v),
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


