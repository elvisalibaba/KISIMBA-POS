import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../auth/auth_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authStore,
    required this.account,
  });
  final AuthStore authStore;
  final LocalAccount account;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    if (_pin.text.length != 4 && _pin.text.length != 6) {
      setState(() => _error = 'Entrez votre PIN de 4 ou 6 chiffres.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final valid = await widget.authStore.unlock(
      widget.account.phoneNumber,
      _pin.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (valid) {
      openWorkspace(context, widget.account);
    } else {
      setState(() => _error = 'Code PIN incorrect. Réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.storefront_rounded,
                  size: 72,
                  color: Color(0xff176b45),
                ),
                const SizedBox(height: 20),
                Text(
                  'Bonjour ${widget.account.fullName.split(' ').first}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(widget.account.businessName, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                TextField(
                  controller: _pin,
                  obscureText: true,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, letterSpacing: 10),
                  decoration: InputDecoration(
                    labelText: 'Votre code PIN',
                    errorText: _error,
                    counterText: '',
                  ),
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: Text(_busy ? 'Ouverture…' : 'Ouvrir ma boutique'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text('PIN oublié ? Récupérer par téléphone'),
                ),
                const Text(
                  'La connexion Internet n’est pas nécessaire.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
