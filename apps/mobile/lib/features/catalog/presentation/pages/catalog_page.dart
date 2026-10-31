import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../explore/data/datasources/salon_preview_catalog.dart';
import '../../../explore/domain/entities/place.dart';
import '../../../explore/presentation/bloc/explore_bloc.dart';
import '../../../home/presentation/pages/popular_services_page.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../../../home/presentation/widgets/salon_summary.dart';

const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF0B0E14);
const _muted = Color(0xFF8C8A94);
const _background = Color(0xFFFDF4F9);

/// A catalog tile. [serviceIds] link it to the services salons offer;
/// categories without them have no salons yet.
class _Category {
  const _Category(this.id, [this.serviceIds = const []]);

  final String id;
  final List<String> serviceIds;

  /// Translations break long labels into the two lines of the design.
  String get label => 'catalog.categories.$id'.tr();
  String get image => 'assets/images/catalog/$id.jpg';
}

const _categories = [
  _Category('nails', ['manicure', 'pedicure']),
  _Category('hair', ['haircut', 'styling']),
  _Category('makeup'),
  _Category('brows_lashes', ['brows', 'lashes']),
  _Category('body_spa'),
  _Category('cosmetology', ['facial']),
  _Category('mens'),
  _Category('face_skin', ['facial']),
  _Category('epilation'),
  _Category('permanent'),
  _Category('solarium'),
  _Category('massage'),
  _Category('piercing'),
  _Category('dental'),
  _Category('aroma'),
  _Category('foot', ['pedicure']),
  _Category('hammam'),
  _Category('barbershop'),
  _Category('body_art'),
  _Category('beauty_combo'),
];

/// Collections shown five per row under the categories.
const _collections = [
  _Category('together'),
  _Category('premium'),
  _Category('gifts'),
  _Category('top_masters'),
  _Category('new'),
];

/// A category with several services opens their grid, one service opens its
/// salons directly, and one without salons says it is coming soon.
void _open(BuildContext context, _Category category) {
  final places = context.read<ExploreBloc>().state.maybeWhen(
    success: (places) => places,
    orElse: () => const <Place>[],
  );
  final offers = [
    for (final offer in SalonPreviewCatalog.offersFor(places))
      if (category.serviceIds.contains(offer.service.id)) offer,
  ];
  int order(ServiceOffers offer) =>
      category.serviceIds.indexOf(offer.service.id);
  offers.sort((a, b) => order(a).compareTo(order(b)));
  final title = category.label.replaceAll('\n', ' ');
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => switch (offers) {
        [] => CatalogSoonPage(title: title),
        [final offer] => ServiceSalonsPage(offer: offer),
        _ => PopularServicesPage(offers: offers, title: title),
      },
    ),
  );
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: DefaultTextStyle.merge(
      style: const TextStyle(height: 1.2),
      child: SafeArea(
        bottom: false,
        child: ListView(
          // Leaves room for the floating bottom navigation.
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
          children: [
            HomeCityBar(
              keyPrefix: 'catalog',
              showCity: false,
              leading: Text(
                'catalog.title'.tr(),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const HomeSearchRow(keyPrefix: 'catalog'),
            const SizedBox(height: 6),
            Text(
              'catalog.subtitle'.tr(),
              style: const TextStyle(color: _muted, fontSize: 15.5),
            ),
            const SizedBox(height: 16),
            const _Grid(categories: _categories, columns: 4, gap: 8),
            const SizedBox(height: 8),
            const _Grid(categories: _collections, columns: 5, gap: 7),
          ],
        ),
      ),
    ),
  );
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.categories,
    required this.columns,
    required this.gap,
  });

  final List<_Category> categories;
  final int columns;
  final double gap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var start = 0; start < categories.length; start += columns) ...[
        if (start > 0) SizedBox(height: gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = start; index < start + columns; index++) ...[
              if (index > start) SizedBox(width: gap),
              Expanded(
                child: index < categories.length
                    ? _Tile(category: categories[index], compact: columns > 4)
                    : const SizedBox(),
              ),
            ],
          ],
        ),
      ],
    ],
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.category, required this.compact});

  final _Category category;

  /// Five-per-row tiles are too narrow for a separate arrow, so it follows
  /// the label's last line instead.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = category.label;
    final style = TextStyle(
      color: _ink,
      fontSize: compact ? 10 : 10.5,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
    final chevron = Icon(
      Icons.chevron_right_rounded,
      color: _pink,
      size: compact ? 12 : 13,
    );
    // Labels keep their line breaks and shrink to fit the tile.
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            if (compact)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: chevron,
              ),
          ],
        ),
        softWrap: false,
        style: style,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCFE),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12C2185B),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('catalog-category-${category.id}'),
          onTap: () => _open(context, category),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: AspectRatio(
                    aspectRatio: compact ? 1.6 : 1.7,
                    child: Image.asset(category.image, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(
                  // Room for two lines.
                  height: compact ? 32 : 34,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: compact
                        ? Align(alignment: Alignment.centerLeft, child: text)
                        : Row(
                            children: [
                              Expanded(child: text),
                              chevron,
                            ],
                          ),
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

/// Category without salons yet.
class CatalogSoonPage extends StatelessWidget {
  const CatalogSoonPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: DefaultTextStyle.merge(
      style: const TextStyle(height: 1.2),
      child: SafeArea(
        child: Column(
          children: [
            ListPageHeader(title: title),
            Expanded(
              child: AppEmptyState(
                icon: Icons.auto_awesome_outlined,
                title: 'catalog.soon_title'.tr(),
                description: 'catalog.soon_description'.tr(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
