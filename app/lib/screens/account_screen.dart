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
  bool _editing = false;
  String? _message;
  String _name = '';
  String _email = '';
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await AuthService.getProfile();
    if (!mounted) return;
    if (result['success'] == true && result['user'] is Map<String, dynamic>) {
      final user = result['user'] as Map<String, dynamic>;
      _name = (user['name'] ?? '').toString();
      _email = (user['email'] ?? '').toString();
      _deviceId = (user['deviceId'] ?? '').toString();
      _nameCtrl.text = _name;
      _emailCtrl.text = _email;
      _deviceCtrl.text = _deviceId;
    } else {
      _message = result['message']?.toString() ?? 'Failed to load profile';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await AuthService.updateProfile(
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      deviceId: _deviceCtrl.text.trim().isEmpty ? null : _deviceCtrl.text.trim(),
      password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
    );
    setState(() {
      _loading = false;
      _message = result['success'] == true ? "Profile updated" : (result['message']?.toString() ?? "Update failed");
      _editing = result['success'] != true;
      if (result['success'] == true) {
        _name = _nameCtrl.text.trim();
        _deviceId = _deviceCtrl.text.trim();
        _passwordCtrl.clear();
      }
    });
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _message = null;
      _nameCtrl.text = _name;
      _deviceCtrl.text = _deviceId;
      _passwordCtrl.clear();
    });
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _message = null;
      _nameCtrl.text = _name;
      _deviceCtrl.text = _deviceId;
      _passwordCtrl.clear();
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
            CircleAvatar(
              radius: 32,
              child: Text(
                (_name.isNotEmpty ? _name[0] : '?').toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              enabled: _editing,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              enabled: false,
              decoration: const InputDecoration(labelText: "Email (not editable)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceCtrl,
              enabled: _editing,
              decoration: const InputDecoration(labelText: "Device ID"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              enabled: _editing,
              decoration: const InputDecoration(labelText: "Password (optional to change)"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_message != null) Text(_message!),
            if (!_editing)
              ElevatedButton(
                onPressed: _loading ? null : _startEdit,
                child: _loading ? const CircularProgressIndicator() : const Text("Edit"),
              ),
            if (_editing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _cancelEdit,
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading ? const CircularProgressIndicator() : const Text("Save"),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
