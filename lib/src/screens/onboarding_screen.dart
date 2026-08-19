import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../auth/auth_store.dart';
import '../auth/phone_number.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.authStore});
  final AuthStore authStore;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _types = [
    'Boutique / Alimentation',
    'Dépôt de boissons',
    'Take-away / Restaurant',
    'Perruques & Articles femme',
    'Habillement mixte & Bijoux',
    'Pharmacie',
    'Cosmétique',
    'Quincaillerie',
    'Téléphones & Accessoires',
    'Vente au marché',
    'Autre activité',
  ];
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _business = TextEditingController();
  final _city = TextEditingController(text: 'Kinshasa');
  final _commune = TextEditingController();
  final _neighborhood = TextEditingController();
  final _pin = TextEditingController();
  final _confirmPin = TextEditingController();
  int _step = 0;
  String _type = _types.first;
  String _currency = 'CDF';
  String? _error;
  bool _busy = false;

  bool _validStep() {
    String? error;
    if (_step == 0) {
      if (normalizeCongolesePhone(_phone.text) == null) {
        error = 'Entrez un numéro congolais valide.';
      }
      if (_name.text.trim().length < 2) error = 'Entrez votre nom complet.';
    } else if (_step == 1 && _business.text.trim().length < 2) {
      error = 'Entrez le nom de votre boutique.';
    } else if (_step == 3) {
      if (!RegExp(r'^(?:[0-9]{4}|[0-9]{6})$').hasMatch(_pin.text)) {
        error = 'Le PIN doit contenir 4 ou 6 chiffres.';
      }
      if (_pin.text != _confirmPin.text) {
        error = 'Les deux codes PIN sont différents.';
      }
    }
    setState(() => _error = error);
    return error == null;
  }

  Future<void> _next() async {
    if (!_validStep()) return;
    if (_step < 3) {
      setState(() {
        _step++;
        _error = null;
      });
      return;
    }
    setState(() => _busy = true);
    try {
      final account = await widget.authStore.register(
        RegistrationData(
          phoneNumber: _phone.text,
          fullName: _name.text,
          businessName: _business.text,
          businessType: _type,
          pin: _pin.text,
          city: _optional(_city.text),
          commune: _optional(_commune.text),
          neighborhood: _optional(_neighborhood.text),
          primaryCurrency: _currency,
        ),
      );
      if (mounted) openFirstProduct(context, account);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Impossible de créer le compte. Vérifiez les informations.';
        });
      }
    }
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  @override
  void dispose() {
    for (final controller in [
      _phone,
      _name,
      _business,
      _city,
      _commune,
      _neighborhood,
      _pin,
      _confirmPin,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: _step == 0
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _step--;
                _error = null;
              }),
            ),
      title: const Text('Créer ma boutique'),
      centerTitle: true,
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i <= _step
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  [
                    'Qui êtes-vous ?',
                    'Votre boutique',
                    'Où êtes-vous ?',
                    'Protégez votre compte',
                  ][_step],
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    'Étape 1 sur 4',
                    'Étape 2 sur 4',
                    'Étape facultative — vous pouvez passer',
                    'Étape 4 sur 4',
                  ][_step],
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(key: ValueKey(_step), child: _content()),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('primaryAction'),
                  onPressed: _busy ? null : _next,
                  child: Text(
                    _busy
                        ? 'Création…'
                        : _step == 3
                        ? 'Créer ma boutique'
                        : 'Continuer',
                  ),
                ),
                if (_step == 2)
                  TextButton(
                    onPressed: () => setState(() {
                      _city.clear();
                      _commune.clear();
                      _neighborhood.clear();
                      _step++;
                    }),
                    child: const Text('Passer cette étape'),
                  ),
                if (_step == 0)
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text(
                      'Pas besoin de Gmail ni d’adresse email.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _content() {
    if (_step == 0) {
      return Column(
        children: [
          TextField(
            key: const Key('phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '082 491 6124',
              prefixText: '+243  ',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('fullName'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nom complet'),
          ),
        ],
      );
    }
    if (_step == 1) {
      return Column(
        children: [
          TextField(
            key: const Key('businessName'),
            controller: _business,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nom de la boutique'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type de commerce'),
            items: _types
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _type = value!),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'CDF', label: Text('Franc CDF')),
              ButtonSegment(value: 'USD', label: Text('Dollar USD')),
            ],
            selected: {_currency},
            onSelectionChanged: (value) =>
                setState(() => _currency = value.first),
          ),
        ],
      );
    }
    if (_step == 2) {
      return Column(
        children: [
          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'Ville (facultatif)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commune,
            decoration: const InputDecoration(
              labelText: 'Commune (facultatif)',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _neighborhood,
            decoration: const InputDecoration(
              labelText: 'Quartier (facultatif)',
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        TextField(
          key: const Key('pin'),
          controller: _pin,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Code PIN (4 ou 6 chiffres)',
            counterText: '',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('confirmPin'),
          controller: _confirmPin,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Confirmer le code PIN',
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.offline_bolt_outlined, color: Color(0xff176b45)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Après la première vérification, ce PIN ouvre votre boutique même sans Internet.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
