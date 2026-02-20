import 'package:flutter/material.dart';
import 'package:g_one/utils/languages.dart';
import 'package:g_one/widgets/section_card.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  String source = 'isl';
  String target = 'hi';
  String outputText = '—';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Translate')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Target Language',
            subtitle: 'Select output language for translation',
            child: DropdownButtonFormField<String>(
              value: target,
              items: [
                for (final lang in LanguagesData.supported)
                  DropdownMenuItem(value: lang.code, child: Text(lang.name))
              ],
              onChanged: (val) => setState(() => target = val ?? target),
            ),
          ),
          SectionCard(
            title: 'Live Output',
            subtitle: 'Translated text from ISL',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(outputText, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          const SectionCard(
            title: 'Note',
            subtitle: 'This is UI only. Bluetooth/AI integration will be added later.',
          ),
        ],
      ),
    );
  }
}


