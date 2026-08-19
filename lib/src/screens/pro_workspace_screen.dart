import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_store.dart';
import '../printing/bixolon_printer.dart';
import '../products/barcode_catalog.dart';
import 'barcode_scanner_screen.dart';

class ProWorkspaceScreen extends StatefulWidget {
  const ProWorkspaceScreen({
    super.key,
    required this.account,
    this.startWithProductForm = false,
  });
  final LocalAccount account;
  final bool startWithProductForm;

  @override
  State<ProWorkspaceScreen> createState() => _ProWorkspaceScreenState();
}

class _ProWorkspaceScreenState extends State<ProWorkspaceScreen> {
  int _tab = 0;
  bool _hideMoney = false;
  final List<_Product> _products = [];
  final List<_Seller> _sellers = [];
  final List<_SaleRecord> _saleHistory = [];
  final Map<_Product, int> _cart = {};
  final BixolonPrinter _printer = BixolonPrinter();
  String _productSearch = '';
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    if (widget.startWithProductForm) {
      _tab = 2;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showProductForm());
    }
    _restoreData();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.account.businessName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const Text(
            'Espace professionnel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.black54,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: _hideMoney ? 'Afficher les montants' : 'Cacher les montants',
          onPressed: () => setState(() => _hideMoney = !_hideMoney),
          icon: Icon(
            _hideMoney
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            backgroundColor: const Color(0xff176b45),
            foregroundColor: Colors.white,
            foregroundImage: _logoPath == null
                ? null
                : FileImage(File(_logoPath!)),
            child: _logoPath == null
                ? Text(widget.account.fullName.substring(0, 1).toUpperCase())
                : null,
          ),
        ),
      ],
    ),
    body: IndexedStack(
      index: _tab,
      children: [_home(), _sales(), _stock(), _team(), _more()],
    ),
    bottomNavigationBar: _PremiumNavigation(
      selectedIndex: _tab,
      onSelected: (value) => setState(() => _tab = value),
    ),
  );

  Widget _home() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff0b6b43), Color(0xff19a868)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33176b45),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0x33ffffff),
              foregroundColor: Colors.white,
              child: Icon(Icons.cloud_done_outlined),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mode hors connexion prêt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Continuez à vendre. La synchronisation se fera automatiquement.',
                    style: TextStyle(color: Color(0xddffffff), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle, color: Color(0xff8ff0b7)),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour ${widget.account.fullName.split(' ').first} 👋',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Voici la situation de votre boutique aujourd’hui.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const Chip(
            avatar: Icon(Icons.verified_user_outlined, size: 18),
            label: Text('Administrateur'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _Metric(
            label: 'Ventes du jour',
            value: _money(
              '${_saleHistory.fold<int>(0, (sum, sale) => sum + sale.total)} CDF',
            ),
            icon: Icons.trending_up,
            color: const Color(0xff176b45),
          ),
          _Metric(
            label: 'Bénéfice estimé',
            value: _money(
              '${_saleHistory.fold<int>(0, (sum, sale) => sum + sale.profit)} CDF',
            ),
            icon: Icons.savings_outlined,
            color: const Color(0xff157a9c),
          ),
          _Metric(
            label: 'Dépenses',
            value: _money('0 CDF'),
            icon: Icons.receipt_long_outlined,
            color: const Color(0xffd97706),
          ),
          _Metric(
            label: 'Dettes clients',
            value: _money('0 CDF'),
            icon: Icons.people_outline,
            color: const Color(0xff7c3aed),
          ),
        ],
      ),
      const SizedBox(height: 26),
      Text(
        'Actions rapides',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _Action(
              icon: Icons.point_of_sale,
              label: 'Nouvelle vente',
              primary: true,
              onTap: () => setState(() => _tab = 1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Action(
              icon: Icons.add_box_outlined,
              label: 'Ajouter produit',
              onTap: _showProductForm,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _Notice(
        icon: _products.isEmpty
            ? Icons.inventory_2_outlined
            : Icons.check_circle_outline,
        title: _products.isEmpty
            ? 'Votre stock est vide'
            : '${_products.length} produit(s) en stock',
        text: _products.isEmpty
            ? 'Ajoutez votre premier produit pour commencer à vendre.'
            : 'Votre boutique est prête pour les ventes.',
      ),
    ],
  );

  Widget _sales() {
    if (_products.isEmpty) {
      return _EmptyPage(
        icon: Icons.point_of_sale,
        title: 'Nouvelle vente',
        subtitle: 'Ajoutez d’abord un produit au stock.',
        button: 'Ajouter un produit',
        onPressed: _showProductForm,
      );
    }
    final total = _cart.entries.fold<int>(
      0,
      (sum, item) => sum + item.key.price * item.value,
    );
    final visibleProducts = _products.where((product) {
      final query = _productSearch.trim().toLowerCase();
      return query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.barcode?.contains(query) ?? false);
    }).toList();
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff073f2b), Color(0xff16875a)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0x33ffffff),
                foregroundColor: Colors.white,
                child: Icon(Icons.point_of_sale),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caisse ouverte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${widget.account.fullName} • Mode hors ligne',
                      style: const TextStyle(
                        color: Color(0xddffffff),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_user, color: Color(0xff8ff0b7)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: Column(
            children: [
              TextField(
                onChanged: (value) => setState(() => _productSearch = value),
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Scanner pour trouver',
                    onPressed: _scanProductForSale,
                    icon: const Icon(Icons.qr_code_scanner),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Chip(label: Text('Tous')),
                    SizedBox(width: 8),
                    Chip(
                      avatar: Icon(Icons.local_drink_outlined, size: 17),
                      label: Text('Boissons'),
                    ),
                    SizedBox(width: 8),
                    Chip(
                      avatar: Icon(Icons.fastfood_outlined, size: 17),
                      label: Text('Alimentation'),
                    ),
                    SizedBox(width: 8),
                    Chip(label: Text('Autres')),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
              childAspectRatio: .78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: visibleProducts.length,
            itemBuilder: (_, i) {
              final product = visibleProducts[i];
              final count = _cart[product] ?? 0;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: product.quantity <= count
                      ? null
                      : () => setState(() => _cart[product] = count + 1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xffe8f5ed),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: _productImage(product),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${product.category} • ${product.quantity} disponible(s)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${product.price} CDF',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: const Color(0xff176b45),
                              foregroundColor: Colors.white,
                              child: Text(
                                count == 0 ? '+' : '$count',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_cart.isNotEmpty)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_cart.values.fold<int>(0, (a, b) => a + b)} article(s)',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        Text(
                          '$total CDF',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _checkout,
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Payer & imprimer'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _stock() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Mon stock',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: _showProductForm,
              icon: const Icon(Icons.add),
              label: const Text('Produit'),
            ),
          ],
        ),
      ),
      Expanded(
        child: _products.isEmpty
            ? const Center(child: Text('Aucun produit pour le moment.'))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final product = _products[i];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: SizedBox.square(
                        dimension: 52,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _productImage(product),
                        ),
                      ),
                      title: Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${product.category} • ${product.quantity} ${product.saleUnit.toLowerCase()}(s) • coût ${product.purchaseUnitPrice.toStringAsFixed(0)} CDF'
                        '${product.expiryDate == null ? '' : ' • expire ${product.expiryDate!.day}/${product.expiryDate!.month}/${product.expiryDate!.year}'}',
                      ),
                      trailing: Text(
                        '${product.price} CDF',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  );
                },
              ),
      ),
    ],
  );

  Widget _team() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mon équipe',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${_sellers.length} vendeur(s) sur 5',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: _sellers.length >= 5 ? null : _showSellerForm,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Inviter'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(child: Text(widget.account.fullName[0])),
          title: Text(
            widget.account.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(widget.account.phoneNumber),
          trailing: const Chip(label: Text('Admin')),
        ),
      ),
      ..._sellers.map(
        (seller) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(child: Text(seller.name[0])),
            title: Text(
              seller.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(seller.phone),
            trailing: const Chip(label: Text('Vendeur')),
          ),
        ),
      ),
      if (_sellers.length >= 5)
        const _Notice(
          icon: Icons.info_outline,
          title: 'Limite atteinte',
          text: 'Une boutique peut avoir au maximum 5 vendeurs, en plus de son administrateur.',
        ),
    ],
  );

  Widget _more() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Plus',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 16),
      Card(
        child: ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Historique ventes et achats'),
          subtitle: Text('${_saleHistory.length} vente(s) conservée(s)'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showSalesHistory,
        ),
      ),
      Card(
        child: ListTile(
          leading: _logoPath == null
              ? const Icon(Icons.add_photo_alternate_outlined)
              : CircleAvatar(backgroundImage: FileImage(File(_logoPath!))),
          title: const Text('Logo de la boutique'),
          subtitle: const Text('Renforcer votre identité sur la caisse'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _chooseShopLogo,
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.store_mall_directory_outlined),
          title: const Text('Prix du marché & grossistes'),
          subtitle: const Text('Sources RDC actualisées'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showMarketSources,
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('Dépenses'),
          subtitle: const Text('Transport, courant, loyer et autres'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openLedger('Dépenses', Icons.receipt_long_outlined),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Dettes clients'),
          subtitle: const Text('Crédits accordés et remboursements'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openLedger('Dettes clients', Icons.people_outline),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.bar_chart_outlined),
          title: const Text('Rapports'),
          subtitle: const Text('Ventes, bénéfice et état du stock'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openReports,
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Paramètres'),
          subtitle: const Text('Boutique, sécurité et imprimante'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openSettings,
        ),
      ),
    ],
  );

  String _money(String value) => _hideMoney ? '••••••' : value;

  Widget _productImage(_Product product) {
    if (product.localImagePath != null &&
        File(product.localImagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(File(product.localImagePath!), fit: BoxFit.cover),
      );
    }
    if (product.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          product.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.shopping_basket_outlined,
            size: 54,
            color: Color(0xff176b45),
          ),
        ),
      );
    }
    return const Center(
      child: Icon(
        Icons.shopping_basket_outlined,
        size: 54,
        color: Color(0xff176b45),
      ),
    );
  }

  Future<void> _scanProductForSale() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || !mounted) return;
    final product = _products.cast<_Product?>().firstWhere(
      (item) => item?.barcode == code,
      orElse: () => null,
    );
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit inconnu. Ajoutez-le d’abord dans le stock.'),
        ),
      );
      return;
    }
    setState(() => _cart[product] = (_cart[product] ?? 0) + 1);
  }

  void _showSalesHistory() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          _SalesHistoryScreen(sales: List.unmodifiable(_saleHistory)),
    ),
  );

  void _showMarketSources() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const _MarketSourcesScreen()));

  Future<void> _chooseShopLogo() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 900,
      );
      if (image == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final saved = await File(image.path).copy(
        '${directory.path}/shop_logo_${widget.account.phoneNumber.replaceAll('+', '')}.jpg',
      );
      if (!mounted) return;
      setState(() => _logoPath = saved.path);
      await _persistData();
    } on MissingPluginException {
      _showNativePluginMessage();
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Impossible d’ouvrir les photos.'),
          ),
        );
      }
    }
  }

  void _showNativePluginMessage() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restart_alt, size: 46),
        title: const Text('Redémarrage nécessaire'),
        content: const Text(
          'Le module caméra/photos vient d’être ajouté. Fermez complètement l’application puis relancez-la avec flutter run. Un hot reload ne suffit pas.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _openLedger(String title, IconData icon) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _LedgerScreen(title: title, icon: icon),
    ),
  );
  void _openReports() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _ReportsScreen(
        sales: List.unmodifiable(_saleHistory),
        products: List.unmodifiable(_products),
      ),
    ),
  );
  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _SettingsScreen(
        account: widget.account,
        logoPath: _logoPath,
        onLogo: _chooseShopLogo,
      ),
    ),
  );

  Future<void> _checkout() async {
    final total = _cart.entries.fold<int>(
      0,
      (sum, item) => sum + item.key.price * item.value,
    );
    final payment = await showModalBottomSheet<_PaymentData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PaymentSheet(total: total),
    );
    if (payment == null || !mounted) return;
    final lines = _cart.entries
        .map(
          (item) => ReceiptLine(
            name: item.key.name,
            quantity: item.value,
            unitPrice: item.key.price,
          ),
        )
        .toList();
    final sale = _SaleRecord(
      invoiceNumber: payment.invoiceNumber,
      date: DateTime.now(),
      lines: _cart.entries
          .map(
            (entry) => _SoldLine(
              entry.key.name,
              entry.value,
              entry.key.price,
              entry.key.purchaseUnitPrice,
            ),
          )
          .toList(growable: false),
      total: total,
      received: payment.received,
      change: payment.change,
      method: payment.method,
      customerPhone: payment.customerPhone,
    );
    setState(() {
      _saleHistory.add(sale);
      for (final entry in _cart.entries) {
        entry.key.quantity -= entry.value;
      }
      _cart.clear();
    });
    await _persistData();
    BluetoothPrinter? selected;
    String? printError;
    try {
      final printers = await _printer.pairedPrinters();
      if (!mounted) return;
      if (printers.isNotEmpty) {
        selected = printers.length == 1
            ? printers.first
            : await showDialog<BluetoothPrinter>(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Choisir l’imprimante BIXOLON'),
                  children: printers
                      .map(
                        (printer) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(context, printer),
                          child: ListTile(
                            leading: const Icon(Icons.print_outlined),
                            title: Text(printer.name),
                            subtitle: Text(printer.address),
                          ),
                        ),
                      )
                      .toList(),
                ),
              );
      }
      if (selected != null) {
        await _printer.print(
          printer: selected,
          shopName: widget.account.businessName,
          shopAddress: widget.account.businessAddress?.isNotEmpty == true
              ? widget.account.businessAddress!
              : 'Kinshasa, RDC',
          sellerName: widget.account.fullName,
          lines: lines,
          payment: ReceiptPayment(
            invoiceNumber: payment.invoiceNumber,
            method: payment.method,
            total: total,
            received: payment.received,
            change: payment.change,
            customerPhone: payment.customerPhone,
          ),
        );
      }
    } on PlatformException catch (error) {
      printError = error.message ?? 'Impression Bluetooth impossible.';
    } finally {
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _InvoiceScreen(
              account: widget.account,
              sale: sale,
              printed: selected != null && printError == null,
              printError: printError,
            ),
          ),
        );
      }
    }
  }

  Future<void> _showProductForm() async {
    final draft = await showModalBottomSheet<_ProductDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ProductFormSheet(),
    );
    if (draft != null) {
      setState(() {
        _products.add(
          _Product(
            draft.name,
            draft.salePrice,
            draft.totalUnits,
            draft.barcode,
            purchaseUnitPrice: draft.purchaseUnitPrice,
            packageType: draft.packageType,
            saleUnit: draft.saleUnit,
            category: draft.category,
            expiryDate: draft.expiryDate,
            imageUrl: draft.imageUrl,
            localImagePath: draft.localImagePath,
          ),
        );
        _tab = 2;
      });
      await _persistData();
    }
  }

  Future<void> _persistData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'workspace_${widget.account.phoneNumber}',
      jsonEncode({
        'logo_path': _logoPath,
        'products': _products
            .map(
              (p) => {
                'name': p.name,
                'price': p.price,
                'quantity': p.quantity,
                'barcode': p.barcode,
                'cost': p.purchaseUnitPrice,
                'package': p.packageType,
                'unit': p.saleUnit,
                'category': p.category,
                'expiry': p.expiryDate?.toIso8601String(),
                'image_url': p.imageUrl,
                'image_path': p.localImagePath,
              },
            )
            .toList(),
        'sales': _saleHistory
            .map(
              (s) => {
                'invoice': s.invoiceNumber,
                'date': s.date.toIso8601String(),
                'total': s.total,
                'received': s.received,
                'change': s.change,
                'method': s.method,
                'phone': s.customerPhone,
                'lines': s.lines
                    .map(
                      (l) => {
                        'name': l.name,
                        'quantity': l.quantity,
                        'price': l.price,
                        'cost': l.cost,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      }),
    );
  }

  Future<void> _restoreData() async {
    final raw = (await SharedPreferences.getInstance()).getString(
      'workspace_${widget.account.phoneNumber}',
    );
    if (raw == null || !mounted) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _logoPath = data['logo_path'] as String?;
      final products = (data['products'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(
            (p) => _Product(
              p['name'] as String,
              p['price'] as int,
              p['quantity'] as int,
              p['barcode'] as String?,
              purchaseUnitPrice: (p['cost'] as num).toDouble(),
              packageType: p['package'] as String,
              saleUnit: p['unit'] as String,
              category: p['category'] as String? ?? 'Autre',
              expiryDate: p['expiry'] == null
                  ? null
                  : DateTime.parse(p['expiry'] as String),
              imageUrl: p['image_url'] as String?,
              localImagePath: p['image_path'] as String?,
            ),
          );
      final sales = (data['sales'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(
            (s) => _SaleRecord(
              invoiceNumber: s['invoice'] as String,
              date: DateTime.parse(s['date'] as String),
              total: s['total'] as int,
              received: s['received'] as int,
              change: s['change'] as int,
              method: s['method'] as String,
              customerPhone: s['phone'] as String?,
              lines: (s['lines'] as List)
                  .cast<Map<String, dynamic>>()
                  .map(
                    (l) => _SoldLine(
                      l['name'] as String,
                      l['quantity'] as int,
                      l['price'] as int,
                      (l['cost'] as num).toDouble(),
                    ),
                  )
                  .toList(growable: false),
            ),
          );
      if (mounted) {
        setState(() {
          _products
            ..clear()
            ..addAll(products);
          _saleHistory
            ..clear()
            ..addAll(sales);
        });
      }
    } catch (_) {}
  }

  Future<void> _showSellerForm() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ajouter un vendeur',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Le vendeur recevra une invitation sur son téléphone.'),
            const SizedBox(height: 20),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty &&
                    phone.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Envoyer l’invitation'),
            ),
          ],
        ),
      ),
    );
    if (added == true && _sellers.length < 5) {
      setState(
        () => _sellers.add(_Seller(name.text.trim(), phone.text.trim())),
      );
    }
  }
}

class _SoldLine {
  const _SoldLine(this.name, this.quantity, this.price, this.cost);
  final String name;
  final int quantity;
  final int price;
  final double cost;
}

class _SaleRecord {
  const _SaleRecord({
    required this.invoiceNumber,
    required this.date,
    required this.lines,
    required this.total,
    required this.received,
    required this.change,
    required this.method,
    this.customerPhone,
  });
  final String invoiceNumber;
  final DateTime date;
  final List<_SoldLine> lines;
  final int total;
  final int received;
  final int change;
  final String method;
  final String? customerPhone;
  int get profit => lines.fold<int>(
    0,
    (sum, line) => sum + ((line.price - line.cost) * line.quantity).round(),
  );
}

class _InvoiceScreen extends StatelessWidget {
  const _InvoiceScreen({
    required this.account,
    required this.sale,
    required this.printed,
    this.printError,
  });
  final LocalAccount account;
  final _SaleRecord sale;
  final bool printed;
  final String? printError;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Facture')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.check_circle, size: 66, color: Color(0xff176b45)),
        const SizedBox(height: 10),
        Text(
          account.businessName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          account.businessAddress?.isNotEmpty == true
              ? account.businessAddress!
              : 'Kinshasa, RDC',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Text(
                  'FACTURE ${sale.invoiceNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${sale.date.day}/${sale.date.month}/${sale.date.year} ${sale.date.hour}:${sale.date.minute.toString().padLeft(2, '0')}',
                ),
                const Divider(),
                for (final line in sale.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${line.quantity} × ${line.name}'),
                        ),
                        Text('${line.quantity * line.price} CDF'),
                      ],
                    ),
                  ),
                const Divider(),
                _InvoiceRow('TOTAL', '${sale.total} CDF', bold: true),
                _InvoiceRow('Argent reçu', '${sale.received} CDF'),
                _InvoiceRow('Monnaie rendue', '${sale.change} CDF'),
                _InvoiceRow('Paiement', sale.method),
                _InvoiceRow('Client', sale.customerPhone ?? 'Comptoir'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: printed ? const Color(0xffe8f5ed) : const Color(0xfffff4e5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                printed ? Icons.print : Icons.phone_android,
                color: printed ? const Color(0xff176b45) : Colors.orange,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  printed
                      ? 'Facture imprimée avec succès.'
                      : 'Facture conservée et visible à l’écran.${printError == null ? '' : ' $printError'}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.favorite_outline),
          label: const Text('Merci — Nouvelle vente'),
        ),
      ],
    ),
  );
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.w900 : null),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: bold ? FontWeight.w900 : null),
        ),
      ],
    ),
  );
}

class _SalesHistoryScreen extends StatelessWidget {
  const _SalesHistoryScreen({required this.sales});
  final List<_SaleRecord> sales;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historique sécurisé')),
    body: sales.isEmpty
        ? const Center(child: Text('Aucune vente enregistrée.'))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final sale = sales.reversed.toList()[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.receipt_long_outlined),
                  ),
                  title: Text(
                    '${sale.total} CDF',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${sale.invoiceNumber}\n${sale.lines.length} produit(s) • ${sale.method}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.lock_outline),
                  onTap: () {},
                ),
              );
            },
          ),
  );
}

class _MarketSourcesScreen extends StatelessWidget {
  const _MarketSourcesScreen();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prix du marché RDC')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _Notice(
          icon: Icons.verified_outlined,
          title: 'Prix réellement sourcés',
          text: 'Kisimba ne fabrique pas de prix. Consultez les plateformes RDC puis enregistrez le prix proposé par votre grossiste.',
        ),
        const SizedBox(height: 12),
        _source(
          'AdamAgri — cotations SIMA',
          'Prix des marchés et produits vivriers en RDC',
          'https://adamagri.com/',
        ),
        _source(
          'Market Price DRC',
          'Comparer produits, marchés et provinces',
          'https://marketprice-drc.com/',
        ),
        _source(
          'Ministère de l’Économie',
          'Bulletins officiels de suivi des prix à Kinshasa',
          'https://economie.gouv.cd/',
        ),
      ],
    ),
  );
  Widget _source(String title, String subtitle, String url) => Card(
    child: ListTile(
      leading: const Icon(Icons.open_in_new),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
    ),
  );
}

class _LedgerScreen extends StatefulWidget {
  const _LedgerScreen({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  State<_LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<_LedgerScreen> {
  final List<(String, int, DateTime)> _entries = [];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.add),
      label: const Text('Ajouter'),
    ),
    body: _entries.isEmpty
        ? _EmptyPage(
            icon: widget.icon,
            title: widget.title,
            subtitle: 'Aucune opération pour le moment.',
            button: 'Ajouter maintenant',
            onPressed: _add,
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _entries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final item = _entries[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(widget.icon)),
                  title: Text(
                    item.$1,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${item.$3.day}/${item.$3.month}/${item.$3.year}',
                  ),
                  trailing: Text(
                    '${item.$2} CDF',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              );
            },
          ),
  );
  Future<void> _add() async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ajouter — ${widget.title}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Motif ou nom du client',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Montant',
                suffixText: 'CDF',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isNotEmpty &&
                    int.tryParse(amount.text) != null) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (added == true) {
      setState(
        () => _entries.add((
          name.text.trim(),
          int.parse(amount.text),
          DateTime.now(),
        )),
      );
    }
  }
}

class _ReportsScreen extends StatelessWidget {
  const _ReportsScreen({required this.sales, required this.products});
  final List<_SaleRecord> sales;
  final List<_Product> products;
  @override
  Widget build(BuildContext context) {
    final revenue = sales.fold<int>(0, (sum, item) => sum + item.total);
    final profit = sales.fold<int>(0, (sum, item) => sum + item.profit);
    return Scaffold(
      appBar: AppBar(title: const Text('Rapports')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Vue générale',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _Notice(
            icon: Icons.verified_outlined,
            title: 'Données protégées',
            text: 'Calculées depuis les ventes conservées sur cet appareil.',
          ),
          const SizedBox(height: 14),
          _ReportTile('Chiffre d’affaires', '$revenue CDF', Icons.trending_up),
          _ReportTile('Bénéfice estimé', '$profit CDF', Icons.savings_outlined),
          _ReportTile(
            'Nombre de ventes',
            '${sales.length}',
            Icons.receipt_long_outlined,
          ),
          _ReportTile(
            'Produits en stock',
            '${products.fold<int>(0, (sum, item) => sum + item.quantity)}',
            Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _SettingsScreen extends StatelessWidget {
  const _SettingsScreen({
    required this.account,
    required this.logoPath,
    required this.onLogo,
  });
  final LocalAccount account;
  final String? logoPath;
  final Future<void> Function() onLogo;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Paramètres')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: CircleAvatar(
            radius: 46,
            backgroundColor: const Color(0xff176b45),
            foregroundImage: logoPath == null
                ? null
                : FileImage(File(logoPath!)),
            child: logoPath == null
                ? const Icon(Icons.storefront, size: 42, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          account.businessName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(
          account.businessAddress ?? 'Kinshasa, RDC',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        Card(
          child: ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Changer le logo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await onLogo();
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Imprimante BIXOLON'),
            subtitle: const Text('Bluetooth • ticket automatique'),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Sécurité et code PIN'),
            subtitle: Text(account.phoneNumber),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
        const _Notice(
          icon: Icons.cloud_done_outlined,
          title: 'Mode hors ligne actif',
          text: 'Vos opérations restent disponibles lorsque le réseau est instable.',
        ),
      ],
    ),
  );
}

class _PaymentData {
  const _PaymentData({
    required this.invoiceNumber,
    required this.method,
    required this.received,
    required this.change,
    this.customerPhone,
  });
  final String invoiceNumber;
  final String method;
  final int received;
  final int change;
  final String? customerPhone;
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.total});
  final int total;
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _received = TextEditingController();
  final _customerPhone = TextEditingController();
  String _method = 'Espèces';
  int get _receivedAmount => int.tryParse(_received.text) ?? 0;
  int get _change => _receivedAmount - widget.total;

  @override
  void initState() {
    super.initState();
    _received.text = widget.total.toString();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Encaisser la vente',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff0b6b43), Color(0xff19a868)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL À PAYER',
                  style: TextStyle(
                    color: Color(0xddffffff),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${widget.total} CDF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'Mode de paiement'),
            items: const [
              'Espèces',
              'M-Pesa',
              'Airtel Money',
              'Orange Money',
              'Afrimoney',
              'Banque',
              'Crédit client',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (value) {
              setState(() {
                _method = value!;
                if (_method != 'Espèces') {
                  _received.text = widget.total.toString();
                }
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _received,
            enabled: _method == 'Espèces',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Argent reçu',
              suffixText: 'CDF',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customerPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone du client (facultatif)',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _change < 0
                  ? const Color(0xffffebee)
                  : const Color(0xffe8f5ed),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _change < 0 ? 'Il manque' : 'Monnaie à rendre',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${_change.abs()} CDF',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _change < 0 ? Colors.red : const Color(0xff176b45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _change < 0 ? null : _confirm,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Valider et préparer la facture'),
          ),
        ],
      ),
    ),
  );

  void _confirm() {
    final now = DateTime.now();
    final number =
        'KIS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';
    Navigator.pop(
      context,
      _PaymentData(
        invoiceNumber: number,
        method: _method,
        received: _receivedAmount,
        change: _change,
        customerPhone: _customerPhone.text.trim().isEmpty
            ? null
            : _customerPhone.text.trim(),
      ),
    );
  }
}

class _ProductDraft {
  const _ProductDraft({
    required this.name,
    required this.salePrice,
    required this.totalUnits,
    required this.purchaseUnitPrice,
    required this.packageType,
    required this.saleUnit,
    required this.category,
    this.barcode,
    this.expiryDate,
    this.imageUrl,
    this.localImagePath,
  });
  final String name;
  final int salePrice;
  final int totalUnits;
  final double purchaseUnitPrice;
  final String packageType;
  final String saleUnit;
  final String category;
  final String? barcode;
  final DateTime? expiryDate;
  final String? imageUrl;
  final String? localImagePath;
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet();
  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _packages = TextEditingController(text: '1');
  final _unitsPerPackage = TextEditingController(text: '1');
  final _purchasePrice = TextEditingController();
  final _extraFees = TextEditingController(text: '0');
  final _salePrice = TextEditingController();
  String _packageType = 'Carton';
  String _saleUnit = 'Pièce';
  String _currency = 'CDF';
  String _category = 'Alimentation';
  DateTime? _expiry;
  String? _imageUrl;
  String? _localImagePath;
  bool _lookingUp = false;

  int get _packageCount => int.tryParse(_packages.text) ?? 0;
  int get _unitCount => int.tryParse(_unitsPerPackage.text) ?? 0;
  double get _purchase => double.tryParse(_purchasePrice.text) ?? 0;
  double get _fees => double.tryParse(_extraFees.text) ?? 0;
  int get _totalUnits => _packageCount * _unitCount;
  double get _unitCost =>
      _totalUnits == 0 ? 0 : (_purchase + _fees) / _totalUnits;
  int _suggest(double margin) => (_unitCost * (1 + margin) / 50).ceil() * 50;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .86,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nouveau produit',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const Text(
              'Pensé pour la boutique, le dépôt et le marché.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    height: 170,
                    decoration: BoxDecoration(
                      color: const Color(0xffeef6f1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _localImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              File(_localImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : _imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(_imageUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(
                            Icons.add_a_photo_outlined,
                            size: 54,
                            color: Color(0xff176b45),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Photo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Galerie'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final value = await Navigator.of(context)
                                .push<String>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BarcodeScannerScreen(),
                                  ),
                                );
                            if (value != null) {
                              _barcode.text = value;
                              await _lookupBarcode(value);
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scanner code'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _barcode.clear,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Sans code'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _barcode,
                    onSubmitted: _lookupBarcode,
                    decoration: InputDecoration(
                      labelText: 'Code-barres ou QR (facultatif)',
                      prefixIcon: const Icon(Icons.qr_code_2),
                      suffixIcon: _lookingUp
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: () => _lookupBarcode(_barcode.text),
                              icon: const Icon(Icons.cloud_download_outlined),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit',
                      hintText: 'Ex. Eau Canadian Pure 50 cl',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Type de produit',
                    ),
                    items:
                        const [
                              'Alimentation',
                              'Boisson',
                              'Hygiène',
                              'Cosmétique',
                              'Médicament',
                              'Téléphone & accessoire',
                              'Quincaillerie',
                              'Habillement',
                              'Maison',
                              'Autre',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _category = value!),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('Comment vous l’achetez ?'),
                  DropdownButtonFormField<String>(
                    initialValue: _packageType,
                    decoration: const InputDecoration(
                      labelText: 'Emballage acheté',
                    ),
                    items:
                        const [
                              'Carton',
                              'Casier',
                              'Paquet',
                              'Sac',
                              'Bidon',
                              'Régime',
                              'Plateau',
                              'Pièce',
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _packageType = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _number(
                          _packages,
                          'Nombre de ${_packageType.toLowerCase()}s',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _number(
                          _unitsPerPackage,
                          'Unités dedans',
                          hint: 'Ex. 24',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _saleUnit,
                    decoration: const InputDecoration(
                      labelText: 'Vous vendez par',
                    ),
                    items:
                        const [
                              'Pièce',
                              'Bouteille',
                              'Canette',
                              'Sachet',
                              'Paquet',
                              'Kilogramme',
                              'Litre',
                              'Verre',
                              'Dose',
                            ]
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _saleUnit = v!),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('Prix et bénéfice'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'CDF', label: Text('CDF')),
                      ButtonSegment(value: 'USD', label: Text('USD')),
                    ],
                    selected: {_currency},
                    onSelectionChanged: (v) =>
                        setState(() => _currency = v.first),
                  ),
                  const SizedBox(height: 12),
                  _number(
                    _purchasePrice,
                    'Prix d’achat total',
                    suffix: _currency,
                  ),
                  const SizedBox(height: 12),
                  _number(
                    _extraFees,
                    'Transport + manutention',
                    suffix: _currency,
                  ),
                  const SizedBox(height: 12),
                  _number(
                    _salePrice,
                    'Prix de vente par $_saleUnit',
                    suffix: _currency,
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _packages,
                      _unitsPerPackage,
                      _purchasePrice,
                      _extraFees,
                      _salePrice,
                    ]),
                    builder: (_, _) => _profitCard(),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('Conservation'),
                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      _expiry == null
                          ? 'Date d’expiration (facultative)'
                          : '${_expiry!.day.toString().padLeft(2, '0')}/${_expiry!.month.toString().padLeft(2, '0')}/${_expiry!.year}',
                    ),
                    subtitle: const Text(
                      'Recommandé pour aliments, boissons, cosmétiques et médicaments',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date != null) setState(() => _expiry = date);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Enregistrer dans le stock'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _number(
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffix,
  }) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
    ),
  );

  Widget _profitCard() {
    final sale = double.tryParse(_salePrice.text) ?? 0;
    final profit = sale - _unitCost;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffe8f5ed),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_totalUnits ${_saleUnit.toLowerCase()}(s) disponibles',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          Text(
            'Coût réel par ${_saleUnit.toLowerCase()} : ${_unitCost.toStringAsFixed(0)} $_currency',
          ),
          if (sale > 0)
            Text(
              profit < 0
                  ? 'Attention : vous vendez à perte'
                  : 'Vous gagnez ${profit.toStringAsFixed(0)} $_currency par ${_saleUnit.toLowerCase()}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: profit < 0 ? Colors.red : const Color(0xff176b45),
              ),
            ),
          if (_unitCost > 0) ...[
            const SizedBox(height: 10),
            const Text(
              'Prix suggérés',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final margin in [.10, .15, .20])
                  ActionChip(
                    label: Text(
                      '${_suggest(margin)} $_currency (+${(margin * 100).round()}%)',
                    ),
                    onPressed: () {
                      _salePrice.text = _suggest(margin).toString();
                      setState(() {});
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _save() {
    final sale = int.tryParse(_salePrice.text);
    if (_name.text.trim().isEmpty ||
        sale == null ||
        _totalUnits <= 0 ||
        _purchase <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complétez le nom, les quantités et les prix.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _ProductDraft(
        name: _name.text.trim(),
        salePrice: sale,
        totalUnits: _totalUnits,
        purchaseUnitPrice: _unitCost,
        packageType: _packageType,
        saleUnit: _saleUnit,
        category: _category,
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        expiryDate: _expiry,
        imageUrl: _imageUrl,
        localImagePath: _localImagePath,
      ),
    );
  }

  Future<void> _lookupBarcode(String code) async {
    if (code.trim().isEmpty) return;
    setState(() => _lookingUp = true);
    final found = await BarcodeCatalog().find(code.trim());
    if (!mounted) return;
    setState(() {
      _lookingUp = false;
      if (found != null) {
        if (_name.text.trim().isEmpty && found.name != null) {
          _name.text = [found.brand, found.name].whereType<String>().join(' ');
        }
        _imageUrl = found.imageUrl;
      }
    });
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Produit non trouvé en ligne. Vous pouvez continuer localement.',
          ),
        ),
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1200,
      );
      if (image == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final extension = image.path.split('.').last;
      final saved = await File(image.path).copy(
        '${directory.path}/product_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      if (mounted) {
        setState(() {
          _localImagePath = saved.path;
          _imageUrl = null;
        });
      }
    } on MissingPluginException {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Redémarrage nécessaire'),
          content: const Text(
            'Fermez complètement l’application et relancez flutter run pour activer caméra et galerie.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
    } on PlatformException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ??
                  'Caméra indisponible. Vérifiez les autorisations.',
            ),
          ),
        );
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
    ),
  );
}

class _Product {
  _Product(
    this.name,
    this.price,
    this.quantity,
    this.barcode, {
    required this.purchaseUnitPrice,
    required this.packageType,
    required this.saleUnit,
    required this.category,
    this.expiryDate,
    this.imageUrl,
    this.localImagePath,
  });
  final String name;
  final int price;
  int quantity;
  final String? barcode;
  final double purchaseUnitPrice;
  final String packageType;
  final String saleUnit;
  final String category;
  final DateTime? expiryDate;
  final String? imageUrl;
  final String? localImagePath;
}

class _Seller {
  const _Seller(this.name, this.phone);
  final String name;
  final String phone;
}

class _PremiumNavigation extends StatelessWidget {
  const _PremiumNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_rounded, 'Accueil'),
    (Icons.shopping_bag_rounded, 'Vendre'),
    (Icons.inventory_2_rounded, 'Stock'),
    (Icons.groups_rounded, 'Équipe'),
    (Icons.grid_view_rounded, 'Plus'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.black.withValues(alpha: .05)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_items.length, (index) {
          final selected = selectedIndex == index;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: _items[index].$2,
              child: InkWell(
                key: Key('tab_$index'),
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xff176b45)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _items[index].$1,
                        size: 22,
                        color: selected ? Colors.white : Colors.black45,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _items[index].$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: color.withValues(alpha: .08),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .14),
            foregroundColor: color,
            child: Icon(icon),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;
  @override
  Widget build(BuildContext context) => Card(
    color: primary ? Theme.of(context).colorScheme.primary : Colors.white,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
        child: Column(
          children: [
            Icon(
              icon,
              size: 34,
              color: primary
                  ? Colors.white
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: primary ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.title, required this.text});
  final IconData icon;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(text, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyPage extends StatelessWidget {
  const _EmptyPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onPressed,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 76, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onPressed, child: Text(button)),
          ],
        ),
      ),
    ),
  );
}
