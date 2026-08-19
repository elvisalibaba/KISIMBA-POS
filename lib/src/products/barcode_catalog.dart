import 'dart:convert';

import 'package:http/http.dart' as http;

class CatalogProduct {
  const CatalogProduct({this.name, this.imageUrl, this.brand});
  final String? name;
  final String? imageUrl;
  final String? brand;
}

class BarcodeCatalog {
  Future<CatalogProduct?> find(String barcode) async {
    if (!RegExp(r'^[0-9]{8,14}$').hasMatch(barcode)) return null;
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://world.openfoodfacts.org/api/v2/product/$barcode.json?fields=product_name,brands,image_front_url,image_url',
            ),
            headers: const {'User-Agent': 'KisimbaPOS/1.0 (Kinshasa, RDC)'},
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;
      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;
      return CatalogProduct(
        name: product['product_name'] as String?,
        brand: product['brands'] as String?,
        imageUrl:
            (product['image_front_url'] ?? product['image_url']) as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
