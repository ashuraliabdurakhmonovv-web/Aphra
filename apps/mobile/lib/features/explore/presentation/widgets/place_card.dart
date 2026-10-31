import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/place.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({required this.place, required this.onRoute, super.key});
  final Place place;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.spa_outlined, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(place.address),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 18,
                          color: Color(0xFFE39D3D),
                        ),
                        const SizedBox(width: 4),
                        Text(place.rating.toStringAsFixed(1)),
                        if (place.isVerified) ...[
                          const Spacer(),
                          const Icon(Icons.verified, size: 18),
                          const SizedBox(width: 4),
                          Text('place.verified'.tr()),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: onRoute,
                        icon: const Icon(Icons.directions_outlined, size: 17),
                        label: Text('place.route'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEC008C),
                          side: const BorderSide(color: Color(0xFFFFA4D1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
