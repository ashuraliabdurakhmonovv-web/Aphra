import 'package:flutter/foundation.dart';

class ShopBrand {
  const ShopBrand(this.id, this.name, {this.hasLogo = false});

  final String id;
  final String name;

  /// Brands with a logo are shown in the popular brands row.
  final bool hasLogo;

  String get logo => 'assets/images/shop/brand_$id.png';
}

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.brandId,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.rating,
    required this.reviews,
  });

  final String id;
  final String brandId;
  final String name;
  final String categoryId;
  final int price;
  final double rating;
  final int reviews;

  ShopBrand get brand =>
      ShopPreviewCatalog.brands.firstWhere((brand) => brand.id == brandId);
  String get image => 'assets/images/shop/product_$id.jpg';
}

/// Shop data until the server has a catalog API. Products, like the preview
/// salons, exist only in debug builds.
abstract final class ShopPreviewCatalog {
  static const brands = [
    ShopBrand('dior', 'Dior', hasLogo: true),
    ShopBrand('loreal', 'L’Oréal', hasLogo: true),
    ShopBrand('nyx', 'NYX', hasLogo: true),
    ShopBrand('kerastase', 'Kérastase', hasLogo: true),
    ShopBrand('clinique', 'Clinique', hasLogo: true),
    ShopBrand('estee', 'Estée Lauder'),
    ShopBrand('olaplex', 'Olaplex'),
  ];

  /// Ordered by popularity.
  static List<ShopProduct> get products => kDebugMode ? _products : const [];

  static const _products = [
    ShopProduct(
      id: 'dior_lip_glow',
      brandId: 'dior',
      name: 'Addict Lip Glow',
      categoryId: 'makeup',
      price: 520000,
      rating: 4.9,
      reviews: 128,
    ),
    ShopProduct(
      id: 'estee_double_wear',
      brandId: 'estee',
      name: 'Double Wear',
      categoryId: 'makeup',
      price: 680000,
      rating: 4.8,
      reviews: 96,
    ),
    ShopProduct(
      id: 'kerastase_chroma',
      brandId: 'kerastase',
      name: 'Masque Chroma',
      categoryId: 'hair',
      price: 750000,
      rating: 4.9,
      reviews: 74,
    ),
    ShopProduct(
      id: 'olaplex_no3',
      brandId: 'olaplex',
      name: 'No.3 Hair Perfector',
      categoryId: 'hair',
      price: 420000,
      rating: 4.8,
      reviews: 112,
    ),
  ];
}
