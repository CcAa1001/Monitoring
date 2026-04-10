import 'package:flutter/material.dart';

import '../../data/inventory_repository.dart';
import '../../models/app_user.dart';

class DesktopLoginScreen extends StatefulWidget {
  const DesktopLoginScreen({
    super.key,
    required this.repository,
    required this.onLogin,
  });

  final InventoryRepository repository;
  final void Function(AppUser user) onLogin;

  @override
  State<DesktopLoginScreen> createState() => _DesktopLoginScreenState();
}

class _DesktopLoginScreenState extends State<DesktopLoginScreen> {
  final TextEditingController _badgeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _badgeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final badge = _badgeController.text.trim();
    final password = _passwordController.text;
    if (badge.isEmpty || password.isEmpty) return;

    final user = await widget.repository.authenticate(
      badgeId: badge,
      password: password,
    );

    if (user == null) {
      setState(() {
        _error = 'Invalid badge ID or password.';
      });
      return;
    }

    widget.onLogin(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Equipment-room sign in',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Use your badge ID and password to access the official equipment-room terminal.',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _badgeController,
                    decoration: const InputDecoration(labelText: 'Badge ID'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFEA5455),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Enter equipment-room desk'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
