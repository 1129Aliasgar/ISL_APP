import 'package:flutter/material.dart';
import 'package:g_one/services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _deviceCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await AuthService.updateProfile(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      deviceId: _deviceCtrl.text.trim().isEmpty ? null : _deviceCtrl.text.trim(),
      password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
    );
    setState(() {
      _loading = false;
      _message = result['success'] == true ? "Profile updated" : (result['message']?.toString() ?? "Update failed");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Update Name")),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Update Email")),
            const SizedBox(height: 12),
            TextField(controller: _deviceCtrl, decoration: const InputDecoration(labelText: "Update Device ID")),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: "Update Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_message != null) Text(_message!),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading ? const CircularProgressIndicator() : const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
