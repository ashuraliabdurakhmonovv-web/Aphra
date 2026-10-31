import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../explore/data/datasources/salon_preview_catalog.dart';
import '../../../explore/domain/entities/place.dart';
import '../../../explore/presentation/widgets/salon_photo.dart';
import '../widgets/salon_summary.dart';

const _background = Color(0xFFF7F5FA);

/// "See all" list of the salons shown on the home page.
class PopularSalonsPage extends StatelessWidget {
  const PopularSalonsPage({required this.places, super.key});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final dates = SalonPreviewCatalog.bookingDates(DateTime.now());
    return Scaffold(
      backgroundColor: _background,
      body: DefaultTextStyle.merge(
        style: const TextStyle(height: 1.2),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ListPageHeader(title: 'home.popular_salons'.tr()),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  // Two salons per row; a row is as tall as its taller card.
                  itemCount: (places.length + 1) ~/ 2,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, row) => IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final index in [row * 2, row * 2 + 1]) ...[
                          if (index.isOdd) const SizedBox(width: 12),
                          Expanded(
                            child: index < places.length
                                ? SalonTile(
                                    place: places[index],
                                    dates: dates,
                                    // Clean photos: the home crops carry the
                                    // mockup's rating badge.
                                    photo: SalonPhoto(place: places[index]),
                                    keyPrefix: 'salon-tile',
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
