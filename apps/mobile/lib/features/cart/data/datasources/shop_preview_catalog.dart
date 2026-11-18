import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';

import '../../../explore/data/datasources/place_preview_data.dart';
import '../../../explore/domain/entities/place.dart';

class ShopBrand {
  const ShopBrand(this.id, this.name, {this.hasLogo = false});

  final String id;
  final String name;

  /// Brands with a logo are shown in the popular brands row.
  final bool hasLogo;

  String get logo => 'assets/images/shop/brand_$id.png';
}

/// A color variant of a product, such as a lipstick or foundation shade.
class ShopShade {
  const ShopShade(this.id, this.name, this.color);

  final String id;

  /// The brand's own shade name, the same in every language.
  final String name;
  final Color color;
}

class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.brandId,
    required this.name,
    required this.categoryId,
    required this.typeId,
    required this.sellerId,
    required this.price,
    required this.rating,
    required this.reviews,
    this.shades = const [],
    this.hasLargePhoto = false,
  });

  final String id;
  final String brandId;
  final String name;
  final String categoryId;

  /// The kind of product, shown under its name: `cart.product_types.<id>`.
  final String typeId;

  /// The id of the preview salon that sells the product.
  final int sellerId;
  final int price;
  final double rating;
  final int reviews;
  final List<ShopShade> shades;

  /// Whether there is a photo for the product page; otherwise it shows the
  /// card image.
  final bool hasLargePhoto;

  ShopBrand get brand =>
      ShopPreviewCatalog.brands.firstWhere((brand) => brand.id == brandId);
  String get fullName => '${brand.name} $name';
  String get image => 'assets/images/shop/product_$id.jpg';

  /// A wider photo, 374 × 203, for the large cards of the favorites.
  String get wideImage => 'assets/images/shop/product_${id}_wide.jpg';

  /// Photos of the product page.
  List<String> get photos => [
    hasLargePhoto ? 'assets/images/shop/product_${id}_hero.jpg' : wideImage,
  ];

  Place get seller => PlacePreviewData.models
      .firstWhere((salon) => salon.id == sellerId)
      .toEntity();
}

/// Shop data until the server has a catalog API. Products, like the preview
/// salons that sell them, exist only in debug builds.
abstract final class ShopPreviewCatalog {
  static const brands = [
    ShopBrand('dior', 'Dior', hasLogo: true),
    ShopBrand('loreal', 'L’Oréal', hasLogo: true),
    ShopBrand('nyx', 'NYX', hasLogo: true),
    ShopBrand('kerastase', 'Kérastase', hasLogo: true),
    ShopBrand('clinique', 'Clinique', hasLogo: true),
    ShopBrand('estee', 'Estée Lauder'),
    ShopBrand('olaplex', 'Olaplex'),
    ShopBrand('chanel', 'Chanel'),
  ];

  /// Ordered by popularity.
  static List<ShopProduct> get products => kDebugMode ? _products : const [];

  static ShopProduct product(String id) =>
      _products.firstWhere((product) => product.id == id);

  /// The product with [id], or null when there is none, as in release builds.
  static ShopProduct? find(String id) =>
      products.where((product) => product.id == id).firstOrNull;

  static const _products = [
    ShopProduct(
      id: 'dior_lip_glow',
      brandId: 'dior',
      name: 'Addict Lip Glow',
      categoryId: 'makeup',
      typeId: 'lip_balm',
      sellerId: -1,
      price: 520000,
      rating: 4.9,
      reviews: 128,
      hasLargePhoto: true,
      shades: [
        ShopShade('001', '001 Pink', Color(0xFFF7809F)),
        ShopShade('004', '004 Coral', Color(0xFFF6C3B6)),
        ShopShade('012', '012 Rosewood', Color(0xFFEC9AA3)),
        ShopShade('015', '015 Cherry', Color(0xFFDF5B69)),
      ],
    ),
    ShopProduct(
      id: 'estee_double_wear',
      brandId: 'estee',
      name: 'Double Wear',
      categoryId: 'makeup',
      typeId: 'foundation',
      sellerId: -15,
      price: 680000,
      rating: 4.8,
      reviews: 96,
      shades: [
        ShopShade('1w1', '1W1 Bone', Color(0xFFF0D5BF)),
        ShopShade('2c0', '2C0 Cool Vanilla', Color(0xFFE6C3A7)),
        ShopShade('3w1', '3W1 Tawny', Color(0xFFD7A47E)),
        ShopShade('4n1', '4N1 Shell Beige', Color(0xFFC48E6C)),
      ],
    ),
    ShopProduct(
      id: 'kerastase_chroma',
      brandId: 'kerastase',
      name: 'Masque Chroma',
      categoryId: 'hair',
      typeId: 'hair_mask',
      sellerId: -14,
      price: 750000,
      rating: 4.9,
      reviews: 74,
    ),
    ShopProduct(
      id: 'olaplex_no3',
      brandId: 'olaplex',
      name: 'No.3 Hair Perfector',
      categoryId: 'hair',
      typeId: 'hair_treatment',
      sellerId: -3,
      price: 420000,
      rating: 4.8,
      reviews: 112,
    ),
    ShopProduct(
      id: 'chanel_chance',
      brandId: 'chanel',
      name: 'Chance Eau Tendre',
      categoryId: 'perfume',
      typeId: 'eau_de_parfum',
      sellerId: -9,
      price: 1890000,
      rating: 4.8,
      reviews: 206,
    ),
    ShopProduct(
      id: 'estee_night_repair',
      brandId: 'estee',
      name: 'Night Repair',
      categoryId: 'skin',
      typeId: 'serum',
      sellerId: -12,
      price: 1320000,
      rating: 4.9,
      reviews: 415,
    ),
  ];
}
