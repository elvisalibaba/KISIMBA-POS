import 'package:flutter/material.dart';

class BusinessModeScreen extends StatefulWidget {
  const BusinessModeScreen({
    super.key,
    required this.businessName,
    required this.initialBusinessType,
  });

  final String businessName;
  final String initialBusinessType;

  @override
  State<BusinessModeScreen> createState() => _BusinessModeScreenState();
}

class _BusinessModeScreenState extends State<BusinessModeScreen> {
  late String _selectedType;

  static const List<BusinessActivity> _activities = [
    BusinessActivity(
      id: 'Boutique / Alimentation',
      title: 'Boutique / Alimentation',
      subtitle: 'Produits, boissons, alimentation et articles divers',
      icon: Icons.storefront_outlined,
      features: [
        'Stock simple',
        'Vente au détail',
        'Vente par carton ou unité',
        'Code-barres',
        'Prix d’achat et de vente',
        'Bénéfice',
        'Stock minimum',
      ],
    ),
    BusinessActivity(
      id: 'Take-away / Restaurant',
      title: 'Take-away / Restaurant',
      subtitle: 'Plats, menus, boissons et commandes',
      icon: Icons.restaurant_outlined,
      features: [
        'Plats et menus',
        'Commandes',
        'À emporter',
        'Sur place',
        'Livraison',
        'Ingrédients',
        'Coût de revient',
        'État de préparation',
      ],
    ),
    BusinessActivity(
      id: 'Perruques & Articles femme',
      title: 'Perruques & Articles femme',
      subtitle: 'Perruques, sacs, chaussures, beauté et accessoires',
      icon: Icons.face_retouching_natural_outlined,
      features: [
        'Longueur',
        'Texture',
        'Couleur',
        'Lace',
        'Densité',
        'Variantes',
        'Photos',
        'Articles femme',
      ],
    ),
    BusinessActivity(
      id: 'Habillement mixte & Bijoux',
      title: 'Habillement mixte & Bijoux',
      subtitle: 'Homme, femme, enfant, chaussures et bijoux',
      icon: Icons.checkroom_outlined,
      features: [
        'Tailles',
        'Couleurs',
        'Pointures',
        'Homme / Femme / Enfant',
        'Variantes',
        'Bijoux',
        'Photos',
      ],
    ),
    BusinessActivity(
      id: 'Pharmacie',
      title: 'Pharmacie',
      subtitle: 'Médicaments, lots, expiration et recherche rapide',
      icon: Icons.medication_outlined,
      features: [
        'Nom commercial',
        'DCI / Principe actif',
        'Dosage',
        'Forme',
        'Fabricant',
        'Numéro de lot',
        'Date d’expiration',
        'Alertes expiration',
        'Recherche médicament',
        'Code-barres',
      ],
    ),
    BusinessActivity(
      id: 'Dépôt de boissons',
      title: 'Dépôt de boissons',
      subtitle: 'Casiers, bouteilles, canettes et ventes en gros',
      icon: Icons.local_drink_outlined,
      features: [
        'Casiers',
        'Bouteilles',
        'Canettes',
        'Vente en gros',
        'Vente au détail',
        'Stock',
        'Fournisseurs',
      ],
    ),
    BusinessActivity(
      id: 'Cosmétique',
      title: 'Cosmétique',
      subtitle: 'Parfums, maquillage, soins et produits de beauté',
      icon: Icons.spa_outlined,
      features: [
        'Marques',
        'Variantes',
        'Couleurs',
        'Volumes',
        'Photos',
        'Stock',
      ],
    ),
    BusinessActivity(
      id: 'Quincaillerie',
      title: 'Quincaillerie',
      subtitle: 'Matériaux, outils et équipements',
      icon: Icons.hardware_outlined,
      features: [
        'Références',
        'Marques',
        'Dimensions',
        'Unités',
        'Stock',
        'Vente en gros',
      ],
    ),
    BusinessActivity(
      id: 'Téléphones & Accessoires',
      title: 'Téléphones & Accessoires',
      subtitle: 'Téléphones, câbles, écouteurs et accessoires',
      icon: Icons.phone_android_outlined,
      features: [
        'Marque',
        'Modèle',
        'Couleur',
        'Capacité',
        'IMEI / Série',
        'Accessoires',
      ],
    ),
    BusinessActivity(
      id: 'Vente au marché',
      title: 'Vente au marché',
      subtitle: 'Gestion très simple pour petit commerce',
      icon: Icons.shopping_basket_outlined,
      features: [
        'Stock simple',
        'Prix d’achat',
        'Prix de vente',
        'Quantité',
        'Bénéfice',
      ],
    ),
    BusinessActivity(
      id: 'Autre activité',
      title: 'Autre activité',
      subtitle: 'Configuration générale pour les autres commerces',
      icon: Icons.category_outlined,
      features: [
        'Produits',
        'Catégories',
        'Stock',
        'Prix',
        'Ventes',
        'Dépenses',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = _normalizeType(widget.initialBusinessType);
  }

  String _normalizeType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'alimentation':
      case 'boutique':
      case 'kiosque':
        return 'Boutique / Alimentation';
      case 'restaurant':
        return 'Take-away / Restaurant';
      case 'habillement':
        return 'Habillement mixte & Bijoux';
      case 'téléphones et accessoires':
      case 'telephones et accessoires':
        return 'Téléphones & Accessoires';
      case 'autre':
        return 'Autre activité';
      default:
        final exists = _activities.any((item) => item.id == value);
        return exists ? value : 'Autre activité';
    }
  }

  BusinessActivity get _currentActivity => _activities.firstWhere(
        (item) => item.id == _selectedType,
        orElse: () => _activities.last,
      );

  @override
  Widget build(BuildContext context) {
    final activity = _currentActivity;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon activité')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff073f2b), Color(0xff16875a)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Color(0x33ffffff),
                  foregroundColor: Colors.white,
                  child: Icon(Icons.storefront_outlined),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: Color(0xddffffff),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choisissez votre activité. Kisimba conservera ce profil pour adapter progressivement le stock, la recherche et la caisse.',
                  style: TextStyle(color: Color(0xccffffff), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Type de commerce',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choisissez l’activité qui correspond le mieux à votre commerce.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ..._activities.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ActivityCard(
                activity: item,
                selected: _selectedType == item.id,
                onTap: () => setState(() => _selectedType = item.id),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Profil ${activity.title}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Champs et outils métier prévus pour ce profil :',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: const Color(0xffeef6f1),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: activity.features
                    .map(
                      (feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: Color(0xff176b45),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _selectedType),
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer mon activité'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class BusinessActivity {
  const BusinessActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.features,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> features;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.selected,
    required this.onTap,
  });

  final BusinessActivity activity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: selected ? const Color(0xffe8f5ed) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? const Color(0xff176b45)
                : Colors.black.withValues(alpha: .07),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: selected
                      ? const Color(0xff176b45)
                      : const Color(0xffeef6f1),
                  foregroundColor:
                      selected ? Colors.white : const Color(0xff176b45),
                  child: Icon(activity.icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activity.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? const Color(0xff176b45) : Colors.black26,
                ),
              ],
            ),
          ),
        ),
      );
}
