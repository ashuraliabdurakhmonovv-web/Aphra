import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../explore/data/datasources/salon_preview_catalog.dart';
import '../../../favorites/presentation/favorites.dart';
import '../../../explore/domain/entities/place.dart';
import '../../../explore/presentation/pages/salon_details_page.dart';
import '../../../explore/presentation/pages/salon_profile_page.dart';
import '../../../explore/presentation/widgets/salon_photo.dart';

const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF0B0E14);
const _muted = Color(0xFF8C8A94);

/// Mockup photos of the first preview salons. The Nur Beauty and Lola Studio
/// photos still contain the mockup's rating badge; the card's badge covers it.
const _salonPhotos = {
  -1: 'assets/images/home/salon_nur_beauty.jpg',
  -2: 'assets/images/home/salon_lola_studio.jpg',
  -3: 'assets/images/home/salon_mira_hair.jpg',
};

Widget salonCardImage(Place place) {
  final asset = _salonPhotos[place.id];
  return asset == null
      ? SalonPhoto(place: place)
      : Image.asset(asset, fit: BoxFit.cover);
}

/// Demo catalogs offer the same services; rotating which ones are named keeps
/// neighbouring salons distinguishable.
String serviceLine(Place place, SalonCatalog catalog, {int count = 2}) {
  final services = catalog.services;
  final shift = ((-place.id - 1) * 3 + 1) ~/ 2;
  return [
    for (var i = 0; i < count; i++)
      services[(shift + i) % services.length].name,
  ].join(' · ');
}

String _digits(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ' ',
);

String priceFrom(int amount) => 'home.price_from'.tr(args: [_digits(amount)]);

String price(int amount) => 'home.price'.tr(args: [_digits(amount)]);

String dayLabel(DateTime date) {
  final now = DateTime.now();
  final days = DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  return switch (days) {
    0 => 'home.today'.tr(),
    1 => 'home.tomorrow'.tr(),
    _ =>
      '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}',
  };
}

/// The app theme's 1.45 body line height is looser than the mockup. Material
/// resets the default text style, so cards apply this one themselves.
TextStyle? cardTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.2);

void openSalonPage(BuildContext context, Place place) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => SalonProfilePage(place: place)));

void openBooking(
  BuildContext context,
  Place place, {
  String? serviceId,
  String? specialistId,
}) => Navigator.of(context, rootNavigator: true).push(
  MaterialPageRoute<void>(
    builder: (_) => SalonDetailsPage(
      place: place,
      serviceId: serviceId,
      specialistId: specialistId,
    ),
  ),
);

class InfoChip extends StatelessWidget {
  const InfoChip({
    required this.color,
    required this.child,
    this.height = 21,
    super.key,
  });

  final Color color;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(height / 2),
    ),
    // Hugs the label width while centering it vertically.
    child: Center(widthFactor: 1, child: child),
  );
}

/// Mint "Tomorrow 10:00" chip with the nearest free slot.
class NearestSlotChip extends StatelessWidget {
  const NearestSlotChip({required this.slot, super.key});

  final (DateTime, String) slot;

  @override
  Widget build(BuildContext context) => InfoChip(
    color: const Color(0xFFDFF4EF),
    child: Text.rich(
      TextSpan(
        text: '${dayLabel(slot.$1)} ',
        children: [
          TextSpan(
            text: slot.$2,
            style: const TextStyle(
              color: Color(0xFF1F9D80),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: Color(0xFF26262B), fontSize: 11),
    ),
  );
}

class PriceChip extends StatelessWidget {
  const PriceChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => InfoChip(
    color: const Color(0xFFFCE4EF),
    height: 23,
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: _pink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Back button and title of the "see all" pages.
class ListPageHeader extends StatelessWidget {
  const ListPageHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
    child: Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 1.5,
          shadowColor: const Color(0x332B1430),
          child: InkWell(
            key: const Key('list-back'),
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: const SizedBox.square(
              dimension: 40,
              child: Icon(Icons.arrow_back_rounded, color: _ink, size: 21),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Full-width salon card for lists. With [service] it shows that service's
/// price and slots and offers to book it; otherwise the salon overall.
class SalonRowCard extends StatelessWidget {
  const SalonRowCard({
    required this.place,
    required this.dates,
    this.service,
    super.key,
  });

  final Place place;
  final List<DateTime> dates;
  final SalonService? service;

  @override
  Widget build(BuildContext context) {
    final catalog = SalonPreviewCatalog.forPlace(place);
    final service = this.service;
    final nearest = catalog?.nearestSlot(dates, service: service);
    final details = service != null
        ? '${service.name} · ${'home.minutes'.tr(args: ['${service.durationMinutes}'])}'
        : catalog == null
        ? null
        : serviceLine(place, catalog, count: 3);
    final priceLabel = service != null
        ? price(service.price)
        : catalog == null
        ? null
        : priceFrom(catalog.minPrice);
    const secondary = TextStyle(color: _muted, fontSize: 12);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2B1430),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        textStyle: cardTextStyle(context),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('salon-row-${place.id}'),
          onTap: () => openSalonPage(context, place),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        SalonPhoto(place: place),
                        Positioned(
                          left: 6,
                          top: 6,
                          child: _RatingPill(rating: place.rating),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (place.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified,
                                color: _pink,
                                size: 15,
                              ),
                            ),
                        ],
                      ),
                      if (details != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondary,
                        ),
                      ],
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: _muted,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              place.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (nearest != null) NearestSlotChip(slot: nearest),
                          if (priceLabel != null) PriceChip(label: priceLabel),
                        ],
                      ),
                      if (service != null) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            key: Key('salon-row-book-${place.id}'),
                            onPressed: () => openBooking(
                              context,
                              place,
                              serviceId: service.id,
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: _pink,
                              minimumSize: const Size(0, 32),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'home.book'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vertical salon card: photo, name, services, street, nearest slot and
/// starting price. Used in the home carousel and the "see all" grid.
class SalonTile extends StatelessWidget {
  const SalonTile({
    required this.place,
    required this.dates,
    required this.photo,
    this.width,
    this.keyPrefix = 'home-salon',
    this.onFavorite,
    super.key,
  });

  final Place place;
  final List<DateTime> dates;
  final Widget photo;

  /// Null fills the available width.
  final double? width;
  final String keyPrefix;

  /// Replaces saving or removing the salon on a heart tap.
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final catalog = SalonPreviewCatalog.forPlace(place);
    final nearest = catalog?.nearestSlot(dates);
    // No user location yet, so the street stands in for the distance.
    final street = place.address.split(',').first.trim();
    final services = catalog == null ? null : serviceLine(place, catalog);
    const secondary = TextStyle(color: _muted, fontSize: 11);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2B1430),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        textStyle: cardTextStyle(context),
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('$keyPrefix-${place.id}'),
          onTap: () => openSalonPage(context, place),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                // 148 × 99 on the home page.
                aspectRatio: 1.5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    photo,
                    Positioned(
                      left: 7,
                      top: 6,
                      child: Container(
                        height: 21,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFD40E73),
                              size: 13,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              place.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFF2F2F33),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: ListenableBuilder(
                        listenable: Favorites.shared.salons,
                        builder: (context, _) {
                          final favorite = Favorites.shared.salons.contains(
                            place,
                          );
                          return InkResponse(
                            key: Key('$keyPrefix-favorite-${place.id}'),
                            onTap:
                                onFavorite ??
                                () => Favorites.shared.salons.toggle(place),
                            radius: 18,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
                              child: Icon(
                                favorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: favorite ? _pink : Colors.white,
                                size: 22,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x40000000),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (services != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        services,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: secondary,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      street,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: secondary,
                    ),
                    if (nearest != null) ...[
                      const SizedBox(height: 7),
                      NearestSlotChip(slot: nearest),
                    ],
                    if (catalog != null) ...[
                      const SizedBox(height: 6),
                      PriceChip(label: priceFrom(catalog.minPrice)),
                    ],
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

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFD40E73), size: 12),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFF2F2F33),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
