import 'package:flutter/material.dart';
import 'package:g_one/widgets/section_card.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connect')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionCard(
            title: 'Bluetooth',
            subtitle: 'Scan and connect to G-ONE glove',
            trailing: Icon(Icons.bluetooth_searching),
          ),
          SectionCard(
            title: 'Connection Status',
            subtitle: 'Not connected',
            trailing: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}


