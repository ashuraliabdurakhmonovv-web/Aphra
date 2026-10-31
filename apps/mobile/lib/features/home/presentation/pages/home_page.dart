import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../explore/data/datasources/salon_preview_catalog.dart';
import '../../../explore/domain/entities/place.dart';
import '../../../explore/presentation/bloc/explore_bloc.dart';
import '../../../explore/presentation/widgets/service_photo.dart';
import '../widgets/home_header.dart';
import '../widgets/salon_summary.dart';
import 'popular_salons_page.dart';
import 'popular_services_page.dart';

const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF0B0E14);
const _muted = Color(0xFF8C8A94);
const _background = Color(0xFFF7F5FA);
const _line = Color(0xFFEAE8EF);
const _bannerTop = Color(0xFFFAEAF4);
const _bannerBottom = Color(0xFFF8DFEC);

/// Category shortcuts. The last value is the matching filter chip on the
/// search map; null opens the map unfiltered.
const _categories = [
  ('home.makeup', 'assets/images/home/cat_makeup.jpg', 'Макияж'),
  ('home.hair', 'assets/images/home/cat_hair.jpg', 'Стрижки'),
  ('home.nails', 'assets/images/home/cat_nails.jpg', 'Маникюр'),
  ('home.care', 'assets/images/home/cat_care.jpg', null),
  ('home.cosmetology', 'assets/images/home/cat_cosmetology.jpg', null),
];

/// Home order of the catalog services; unknown ones go last.
const _popularServices = [
  'lashes',
  'manicure',
  'haircut',
  'facial',
  'pedicure',
  'brows',
  'styling',
];

int _popularity(ServiceOffers offer) {
  final rank = _popularServices.indexOf(offer.service.id);
  return rank < 0 ? _popularServices.length : rank;
}

void _push(BuildContext context, Widget page) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => page));

Widget _inset(Widget child) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    // The app theme's 1.45 body line height is looser than the mockup.
    body: DefaultTextStyle.merge(
      style: const TextStyle(height: 1.2),
      child: SafeArea(
        bottom: false,
        child: BlocBuilder<ExploreBloc, ExploreState>(
          builder: (context, state) {
            final places = state.maybeWhen(
              success: (places) => places,
              orElse: () => const <Place>[],
            );
            final offers = SalonPreviewCatalog.offersFor(places)
              ..sort((a, b) => _popularity(a).compareTo(_popularity(b)));
            final loading = state.maybeWhen(
              initial: () => true,
              loading: () => true,
              orElse: () => false,
            );
            return ListView(
              // Leaves room for the floating bottom navigation.
              padding: const EdgeInsets.only(top: 6, bottom: 120),
              children: [
                _inset(const HomeCityBar()),
                const SizedBox(height: 12),
                _inset(const HomeSearchRow()),
                const SizedBox(height: 12),
                _HeroCarousel(salons: places.take(3).toList()),
                const SizedBox(height: 20),
                _inset(const _Categories()),
                const SizedBox(height: 26),
                _inset(
                  _SectionHeader(
                    key: const Key('home-salons-all'),
                    title: 'home.popular_salons'.tr(),
                    onSeeAll: () =>
                        _push(context, PopularSalonsPage(places: places)),
                  ),
                ),
                const SizedBox(height: 12),
                if (loading)
                  const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _pink,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else if (places.isEmpty)
                  _inset(
                    Text(
                      'home.no_salons'.tr(),
                      style: const TextStyle(color: _muted, fontSize: 14),
                    ),
                  )
                else
                  _SalonList(places: places),
                if (offers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _inset(
                    _SectionHeader(
                      key: const Key('home-services-all'),
                      title: 'home.popular_services'.tr(),
                      onSeeAll: () =>
                          _push(context, PopularServicesPage(offers: offers)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceList(offers: offers),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Main promo followed by slides for the first salons from the data.
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.salons});

  final List<Place> salons;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _HeroSlide(
        kicker: 'home.hero_kicker'.tr(),
        title: 'home.hero_title'.tr(),
        action: 'home.hero_action'.tr(),
        onAction: () => openSearch(context),
        image: Image.asset(
          'assets/images/home/hero_woman.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.centerLeft,
        ),
      ),
      for (final place in widget.salons)
        _HeroSlide(
          kicker: 'home.salon_kicker'.tr(),
          title: place.name,
          subtitle:
              '★ ${place.rating.toStringAsFixed(1)}  ·  '
              '${place.address.split(',').first}',
          action: 'home.book'.tr(),
          onAction: () => openBooking(context, place),
          image: salonCardImage(place),
        ),
    ];
    final page = _page.clamp(0, slides.length - 1);
    return Column(
      children: [
        SizedBox(
          height: 142,
          child: PageView(
            key: const Key('home-hero'),
            controller: _controller,
            onPageChanged: (value) => setState(() => _page = value),
            children: [
              for (final slide in slides)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: slide,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < slides.length; index++)
              AnimatedContainer(
                key: Key('home-hero-dot-$index'),
                duration: const Duration(milliseconds: 200),
                width: index == page ? 14 : 5,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: index == page
                      ? const Color(0xFFDC2A9A)
                      : const Color(0xFFCECCD1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({
    required this.kicker,
    required this.title,
    required this.action,
    required this.onAction,
    required this.image,
    this.subtitle,
  });

  final String kicker;
  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback onAction;
  final Widget image;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 0.5;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bannerTop, _bannerBottom],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: imageWidth,
                child: image,
              ),
              // Blends the photo's left edge into the banner background.
              Positioned(
                top: 0,
                bottom: 0,
                right: imageWidth - 36,
                width: 48,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF9E6F1), Color(0x00F9E6F1)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 14,
                bottom: 14,
                width: constraints.maxWidth - imageWidth + 12,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker,
                        style: const TextStyle(
                          color: Color(0xFF8E878E),
                          fontSize: 9,
                          height: 1.3,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 21,
                          height: 1.08,
                          letterSpacing: -0.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: Color(0xFF6F6A72),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: _pink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 31),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(action),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 15),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _Categories extends StatelessWidget {
  const _Categories();

  static const _tileShape = ContinuousRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(36)),
  );

  Widget _item({
    required Key key,
    required String label,
    required Widget tile,
    required VoidCallback onTap,
  }) => SizedBox(
    width: 50,
    child: GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox.square(dimension: 50, child: tile),
          const SizedBox(height: 7),
          // Long labels such as "Косметология" may spread past the tile,
          // as in the mockup.
          SizedBox(
            height: 28,
            child: OverflowBox(
              maxWidth: 84,
              alignment: Alignment.topCenter,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1D1D22),
                    fontSize: 11,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (label, image, category) in _categories)
        _item(
          key: Key('home-category-$label'),
          label: label.tr(),
          onTap: () => openSearch(context, category),
          tile: ClipPath(
            clipper: const ShapeBorderClipper(shape: _tileShape),
            child: Image.asset(image, fit: BoxFit.cover),
          ),
        ),
      _item(
        key: const Key('home-category-more'),
        label: 'home.more'.tr(),
        onTap: () => context.go('/catalog'),
        tile: const DecoratedBox(
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(36)),
              side: BorderSide(color: _line, width: 1.2),
            ),
          ),
          child: Center(child: _MoreIcon()),
        ),
      ),
    ],
  );
}

/// Four rings in a 2×2 grid, as on the "more" tile of the mockup.
class _MoreIcon extends StatelessWidget {
  const _MoreIcon();

  @override
  Widget build(BuildContext context) {
    Widget ring() => Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF717173), width: 1.6),
      ),
    );
    Widget pair() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [ring(), const SizedBox(width: 3.5), ring()],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [pair(), const SizedBox(height: 3.5), pair()],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
    super.key,
  });

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            letterSpacing: -0.2,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      InkWell(
        onTap: onSeeAll,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'home.see_all'.tr(),
                style: const TextStyle(
                  color: _pink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_rounded, color: _pink, size: 16),
            ],
          ),
        ),
      ),
    ],
  );
}

class _SalonList extends StatelessWidget {
  const _SalonList({required this.places});

  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    final dates = SalonPreviewCatalog.bookingDates(DateTime.now());
    return SizedBox(
      height: 236,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        // Cards keep their own height; the list is taller to leave room for
        // larger accessibility text.
        itemBuilder: (context, index) => Align(
          alignment: Alignment.topCenter,
          child: SalonTile(
            place: places[index],
            dates: dates,
            photo: salonCardImage(places[index]),
            width: 148,
          ),
        ),
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({required this.offers});

  final List<ServiceOffers> offers;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 124,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      clipBehavior: Clip.none,
      scrollDirection: Axis.horizontal,
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(width: 9),
      itemBuilder: (context, index) {
        final offer = offers[index];
        return Container(
          width: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D2B1430),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            textStyle: cardTextStyle(context),
            borderRadius: BorderRadius.circular(11),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: Key('home-service-${offer.service.id}'),
              onTap: () => _push(context, ServiceSalonsPage(offer: offer)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    ServicePhoto.of(offer.service),
                    height: 58,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(9, 7, 6, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 29,
                          child: Text(
                            offer.service.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 11,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          priceFrom(offer.minPrice),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
