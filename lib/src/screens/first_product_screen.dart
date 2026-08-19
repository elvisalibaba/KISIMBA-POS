import 'package:flutter/material.dart';

import '../auth/auth_store.dart';
import 'business_workspace_screen.dart';

class FirstProductScreen extends StatelessWidget {
  const FirstProductScreen({super.key, required this.account});
  final LocalAccount account;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 112,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Votre boutique est prête !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  account.businessName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, color: Colors.black54),
                ),
                const SizedBox(height: 34),
                Text(
                  'Ajoutez votre premier produit',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Il sera ensuite prêt à vendre.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => BusinessWorkspaceScreen(
                        account: account,
                        startWithProductForm: true,
                      ),
                    ),
                    (_) => false,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un produit'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
