import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../l10n/language_toggle.dart';
import '../../data/inventory_repository.dart';
import '../../models/app_user.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({
    super.key,
    required this.repository,
    required this.onLogin,
  });

  final InventoryRepository repository;
  final void Function(AppUser user) onLogin;

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final TextEditingController _badgeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
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
    if (badge.isEmpty || password.isEmpty) {
      setState(() {
        _error = tr('Masukkan ID badge dan kata sandi terlebih dahulu.');
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final user = await widget.repository.authenticate(
      badgeId: badge,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (user == null) {
      setState(() {
        _error = tr('ID badge atau kata sandi salah.');
      });
      return;
    }

    widget.onLogin(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageToggleButton(),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0ECFF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF5B39EA),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        tr('Masuk seluler'),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tr('Masuk untuk memantau peralatan dan menggunakan ponsel Anda sebagai pemindai yang tersambung ke desktop ruang peralatan.'),
                        style: const TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _badgeController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: tr('ID badge')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(labelText: tr('Kata sandi')),
                      ),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 12),
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
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(tr('Lanjutkan')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
