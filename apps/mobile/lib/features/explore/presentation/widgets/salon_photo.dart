import 'package:flutter/material.dart';

import '../../domain/entities/place.dart';

/// Demo photos are keyed to preview IDs; API places never inherit a demo photo.
class SalonPhoto extends StatelessWidget {
  const SalonPhoto({required this.place, super.key});

  final Place place;

  static const previewAssets = <int, String>{
    -1: 'assets/images/salons/nur_beauty.jpg',
    -2: 'assets/images/salons/lola_studio.jpg',
    -3: 'assets/images/salons/mira_hair.jpg',
    -4: 'assets/images/salons/sana_brow.jpg',
    -5: 'assets/images/salons/velvet_beauty.jpg',
    -6: 'assets/images/salons/rose_room.jpg',
    -7: 'assets/images/salons/glow_studio.jpg',
    -8: 'assets/images/salons/diva_nails.jpg',
    -9: 'assets/images/salons/bella_line.jpg',
    -10: 'assets/images/salons/aura_salon.jpg',
    -11: 'assets/images/salons/lash_lab.jpg',
    -12: 'assets/images/salons/silk_beauty.jpg',
    -13: 'assets/images/salons/noira_studio.jpg',
    -14: 'assets/images/salons/bloom_hair.jpg',
    -15: 'assets/images/salons/elle_makeup.jpg',
  };

  @override
  Widget build(BuildContext context) {
    final asset = previewAssets[place.id];
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _PhotoFallback(place: place),
      );
    }
    return _PhotoFallback(place: place);
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    const colors = <Color>[
      Color(0xFFB873A0),
      Color(0xFF669D99),
      Color(0xFF8C83BD),
      Color(0xFFB8876C),
      Color(0xFF7997BE),
    ];
    final initials = place.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();

    return ColoredBox(
      color: colors[place.id.abs() % colors.length],
      child: Center(
        child: Text(
          initials.isEmpty ? '✦' : initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
