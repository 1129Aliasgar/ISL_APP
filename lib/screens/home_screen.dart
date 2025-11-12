import 'package:flutter/material.dart';
import 'package:g_one/utils/constants.dart';
import 'package:g_one/widgets/primary_button.dart';
import 'package:g_one/widgets/section_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('G-ONE')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Connect Device',
            subtitle: 'Pair your G-ONE glove via Bluetooth',
            trailing: const Icon(Icons.bluetooth, color: Colors.white70),
            onTap: () => Navigator.pushNamed(context, AppConstants.routeConnect),
          ),
          SectionCard(
            title: 'Translate',
            subtitle: 'ISL to Hindi, English and more',
            trailing: const Icon(Icons.translate, color: Colors.white70),
            onTap: () => Navigator.pushNamed(context, AppConstants.routeTranslate),
          ),
          SectionCard(
            title: 'Settings',
            subtitle: 'Language, pitch, volume and preferences',
            trailing: const Icon(Icons.settings, color: Colors.white70),
            onTap: () => Navigator.pushNamed(context, AppConstants.routeSettings),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Quick Start',
            icon: Icons.play_arrow,
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeTranslate),
          ),
        ],
      ),
    );
  }
}


