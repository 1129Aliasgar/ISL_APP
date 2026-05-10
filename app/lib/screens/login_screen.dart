import 'package:flutter/material.dart';
import 'package:g_one/services/auth_service.dart';
import 'package:g_one/utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
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

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.login(
      identifier: _identifierCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success'] == true) {
      Navigator.pushReplacementNamed(context, AppConstants.routeHome);
    } else {
      setState(() => _error = result['message']?.toString() ?? "Login failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _identifierCtrl, decoration: const InputDecoration(labelText: "Email or Name")),
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
              onPressed: _loading ? null : _login,
              child: _loading ? const CircularProgressIndicator() : const Text("Login"),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeRegister),
              child: const Text("Create account"),
            ),
          ],
        ),
      ),
    );
  }
}
