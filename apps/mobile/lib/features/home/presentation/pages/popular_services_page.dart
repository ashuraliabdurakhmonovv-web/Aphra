import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../explore/data/datasources/salon_preview_catalog.dart';
import '../../../explore/presentation/widgets/service_photo.dart';
import '../widgets/salon_summary.dart';

const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF0B0E14);
const _muted = Color(0xFF8C8A94);
const _background = Color(0xFFF7F5FA);

String _minutes(SalonService service) =>
    'home.minutes'.tr(args: ['${service.durationMinutes}']);

void _openService(BuildContext context, ServiceOffers offer) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => ServiceSalonsPage(offer: offer)),
    );

/// "See all" grid of the services offered by the home page salons, also
/// used for a catalog category.
class PopularServicesPage extends StatelessWidget {
  const PopularServicesPage({required this.offers, this.title, super.key});

  final List<ServiceOffers> offers;

  /// Defaults to "Popular services".
  final String? title;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: DefaultTextStyle.merge(
      style: const TextStyle(height: 1.2),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ListPageHeader(title: title ?? 'home.popular_services'.tr()),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  4,
                  16,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 208,
                ),
                itemCount: offers.length,
                itemBuilder: (context, index) =>
                    _ServiceTile(offer: offers[index]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.offer});

  final ServiceOffers offer;

  @override
  Widget build(BuildContext context) => Container(
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
        key: Key('service-tile-${offer.service.id}'),
        onTap: () => _openService(context, offer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              ServicePhoto.of(offer.service),
              height: 112,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 9, 11, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 36,
                    child: Text(
                      offer.service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceFrom(offer.minPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: _muted,
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _minutes(offer.service),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ),
                    ],
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

/// Salons offering one service, with their price and nearest free slot.
class ServiceSalonsPage extends StatelessWidget {
  const ServiceSalonsPage({required this.offer, super.key});

  final ServiceOffers offer;

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
              ListPageHeader(
                title: offer.service.name,
                subtitle:
                    '${priceFrom(offer.minPrice)} · ${_minutes(offer.service)}',
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  itemCount: offer.salons.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final (place, service) = offer.salons[index];
                    return SalonRowCard(
                      place: place,
                      dates: dates,
                      service: service,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
