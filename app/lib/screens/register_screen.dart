import 'package:flutter/material.dart';
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _deviceCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _redirectIfLoggedIn();
  }

  Future<void> _redirectIfLoggedIn() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted || !loggedIn) return;
    Navigator.pushReplacementNamed(context, AppConstants.routeHome);
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      deviceId: _deviceCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
    } else {
      setState(() => _error = result['message']?.toString() ?? "Registration failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 12),
            TextField(controller: _deviceCtrl, decoration: const InputDecoration(labelText: "Device ID")),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _register,
              child: _loading ? const CircularProgressIndicator() : const Text("Register"),
            ),
          ],
        ),
      ),
    );
  }
}
