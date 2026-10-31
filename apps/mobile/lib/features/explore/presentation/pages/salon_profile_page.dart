import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/platform/maps_launcher.dart';
import '../../data/datasources/salon_preview_catalog.dart';
import '../../domain/entities/place.dart';
import '../widgets/salon_photo.dart';
import '../widgets/service_photo.dart';
import 'salon_details_page.dart';

const _pink = Color(0xFFC8218A);
const _pinkText = Color(0xFFD12D93);
const _ink = Color(0xFF15161B);
const _muted = Color(0xFF8E8D98);
const _background = Color(0xFFF9F8FD);
const _line = Color(0xFFECEAF2);
const _softPink = Color(0xFFFCECF6);
const _star = Color(0xFFEC1292);

/// Mockup photos of the first preview salon. Other preview salons show their
/// single preview photo.
const _galleries = {
  -1: [
    'assets/images/salons/nur_beauty_hero.jpg',
    'assets/images/salons/nur_beauty_1.jpg',
    'assets/images/salons/nur_beauty_2.jpg',
    'assets/images/salons/nur_beauty_3.jpg',
    'assets/images/salons/nur_beauty_4.jpg',
  ],
};

/// Preview salons share these hours (Tashkent time); booking slots fit inside.
const _opensAt = 9;
const _closesAt = 21;

/// Amenities of preview salons; the last value is the label's share of the row.
const _amenities = [
  (Icons.diamond_outlined, 'Профессиональные\nмастера', 16),
  (Icons.verified_user_outlined, 'Чистота\nи безопасность', 16),
  (Icons.percent_rounded, 'Акции\nи скидки', 10),
  (Icons.credit_card_outlined, 'Оплата картой\nи кредитами', 15),
  (null, 'Удобная\nпарковка', 11),
];

/// Placeholder reviews for preview salons until reviews come from the API.
const _demoReviews = [
  (
    'Мадина К.',
    5,
    '12 октября',
    'Маникюр',
    'Очень аккуратная работа и приятная атмосфера. Покрытие держится уже третью неделю.',
  ),
  (
    'Гульнора С.',
    5,
    '3 октября',
    'Брови',
    'Мастер подобрала форму под лицо и всё объяснила. Приду ещё.',
  ),
  (
    'Ирина П.',
    4,
    '27 сентября',
    'Педикюр',
    'Хороший сервис, но пришлось подождать минут десять.',
  ),
];

enum _Section {
  services('Услуги'),
  masters('Мастера'),
  reviews('Отзывы'),
  about('О салоне');

  const _Section(this.label);
  final String label;
}

String _sum(int amount) =>
    '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} сум';

String _plural(int count, String one, String few, String many) {
  final tens = count % 100;
  final units = count % 10;
  if (tens >= 11 && tens <= 14) return many;
  if (units == 1) return one;
  if (units >= 2 && units <= 4) return few;
  return many;
}

/// "ул. Шахрисабз, 12, Ташкент" → "ул. Шахрисабз, 12 · Ташкент".
String _addressLine(String address) {
  const city = ', Ташкент';
  return address.endsWith(city)
      ? '${address.substring(0, address.length - city.length)} · Ташкент'
      : address;
}

String _hour(int hour) => '${hour.toString().padLeft(2, '0')}:00';

/// Material resets the default text style to the theme's 1.45 line height,
/// which is looser than the mockup, so cards apply this one themselves.
TextStyle? _cardTextStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.2, color: _ink);

Widget _inset(Widget child) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);

/// Salon profile: photos, highlights, services, masters, reviews, booking.
class SalonProfilePage extends StatefulWidget {
  const SalonProfilePage({required this.place, super.key});

  final Place place;

  @override
  State<SalonProfilePage> createState() => _SalonProfilePageState();
}

class _SalonProfilePageState extends State<SalonProfilePage> {
  late final SalonCatalog? _catalog = SalonPreviewCatalog.forPlace(
    widget.place,
  );
  late final List<String> _photos =
      _galleries[widget.place.id] ??
      [if (SalonPhoto.previewAssets[widget.place.id] case final asset?) asset];
  final _scroll = ScrollController();
  final _sectionKeys = {
    for (final section in _Section.values) section: GlobalKey(),
  };
  _Section _section = _Section.services;
  bool _jumping = false;
  bool _collapsed = false;
  bool _favorite = false;
  int _photo = 0;

  Place get _place => widget.place;

  double get _topBarHeight => MediaQuery.paddingOf(context).top + 32;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double? _sectionTop(_Section section) {
    final box =
        _sectionKeys[section]!.currentContext?.findRenderObject() as RenderBox?;
    return box == null || !box.attached
        ? null
        : box.localToGlobal(Offset.zero).dy;
  }

  void _onScroll() {
    final collapsed = _scroll.offset > 72;
    var section = _section;
    if (!_jumping) {
      for (final candidate in _Section.values) {
        final top = _sectionTop(candidate);
        if (top != null && top <= _topBarHeight + 60) section = candidate;
      }
      if (_scroll.offset <= 0) section = _Section.services;
    }
    if (collapsed != _collapsed || section != _section) {
      setState(() {
        _collapsed = collapsed;
        _section = section;
      });
    }
  }

  Future<void> _scrollTo(_Section section) async {
    final top = _sectionTop(section);
    if (top == null) return;
    setState(() => _section = section);
    _jumping = true;
    await _scroll.animateTo(
      (_scroll.offset + top - _topBarHeight - 12).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
    _jumping = false;
  }

  void _message(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _book({SalonService? service, SalonSpecialist? specialist}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SalonDetailsPage(
            place: _place,
            serviceId: service?.id,
            specialistId: specialist?.id,
          ),
        ),
      );

  void _bookWith(SalonCatalog catalog, SalonSpecialist specialist) => _book(
    service: catalog.services.firstWhere(
      (service) => specialist.serviceIds.contains(service.id),
    ),
    specialist: specialist,
  );

  void _openGallery(int index) {
    if (_photos.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _GalleryPage(photos: _photos, initialIndex: index),
      ),
    );
  }

  Future<void> _openMap() async {
    final opened = await sl<MapsLauncher>().openDirections(
      latitude: _place.latitude,
      longitude: _place.longitude,
    );
    if (mounted && !opened) _message('Не удалось открыть карты');
  }

  Future<void> _share() async {
    final link = GoogleMapsLauncher.searchUri(
      '${_place.name}, ${_place.address}',
    );
    await Clipboard.setData(
      ClipboardData(text: '${_place.name}\n${_place.address}\n$link'),
    );
    if (mounted) _message('Ссылка на салон скопирована');
  }

  void _openCredits() {
    final router = GoRouter.maybeOf(context);
    Navigator.of(context).popUntil((route) => route.settings is Page);
    router?.go('/profile/payments');
  }

  void _showMasters(SalonCatalog catalog) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) => _MastersSheet(
      catalog: catalog,
      onSelected: (specialist) {
        Navigator.pop(sheetContext);
        _bookWith(catalog, specialist);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    final padding = MediaQuery.paddingOf(context);
    final heroHeight = padding.top + 104;
    final tashkentNow = DateTime.now().toUtc().add(const Duration(hours: 5));
    final open = tashkentNow.hour >= _opensAt && tashkentNow.hour < _closesAt;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _collapsed
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _background,
        body: DefaultTextStyle.merge(
          style: const TextStyle(height: 1.2, color: _ink),
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                padding: EdgeInsets.only(bottom: padding.bottom + 92),
                child: Stack(
                  children: [
                    SizedBox(
                      height: heroHeight + 24,
                      width: double.infinity,
                      child: _Hero(
                        place: _place,
                        photos: _photos,
                        index: _photo,
                        onChanged: (index) => setState(() => _photo = index),
                        onTap: () => _openGallery(_photo),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: heroHeight),
                      decoration: const BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          _inset(
                            _Header(
                              place: _place,
                              catalog: catalog,
                              open: open,
                              onMap: _openMap,
                              onCredits: _openCredits,
                            ),
                          ),
                          if (catalog == null)
                            _inset(
                              const Padding(
                                padding: EdgeInsets.only(top: 24),
                                child: Text(
                                  'Услуги, мастера и отзывы появятся, когда '
                                  'салон подключится к Cosmetic Map.',
                                  style: TextStyle(color: _muted, fontSize: 14),
                                ),
                              ),
                            )
                          else
                            ..._sections(catalog, open),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: _TopBar(
                  title: _place.name,
                  collapsed: _collapsed,
                  favorite: _favorite,
                  onBack: () => Navigator.of(context).maybePop(),
                  onShare: _share,
                  onFavorite: () => setState(() => _favorite = !_favorite),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BookingBar(
                  onCall: () => _message('Телефон салона пока не указан'),
                  onBook: _book,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(SalonCatalog catalog, bool open) => [
    const SizedBox(height: 16),
    _inset(const _Amenities()),
    const SizedBox(height: 18),
    _inset(_Tabs(selected: _section, onSelected: _scrollTo)),
    const SizedBox(height: 20),
    KeyedSubtree(
      key: _sectionKeys[_Section.services],
      child: _inset(
        _SectionHeader(
          title: 'Популярные услуги',
          action: 'Все услуги',
          onAction: _book,
        ),
      ),
    ),
    const SizedBox(height: 10),
    _ServiceList(
      services: catalog.services,
      onSelected: (service) => _book(service: service),
    ),
    const SizedBox(height: 16),
    KeyedSubtree(
      key: _sectionKeys[_Section.masters],
      child: _inset(
        _SectionHeader(
          title: 'Мастера салона',
          action: 'Все мастера',
          onAction: () => _showMasters(catalog),
        ),
      ),
    ),
    const SizedBox(height: 12),
    _MasterList(
      catalog: catalog,
      onSelected: (specialist) => _bookWith(catalog, specialist),
    ),
    if (_photos.length > 1) ...[
      const SizedBox(height: 22),
      _inset(
        _SectionHeader(
          title: 'Фото салона',
          action: 'Все фото',
          onAction: () => _openGallery(0),
        ),
      ),
      const SizedBox(height: 10),
      _inset(_GalleryRow(photos: _photos, onSelected: _openGallery)),
    ],
    const SizedBox(height: 26),
    KeyedSubtree(
      key: _sectionKeys[_Section.reviews],
      child: _inset(_SectionHeader(title: 'Отзывы')),
    ),
    const SizedBox(height: 12),
    _inset(_Reviews(rating: _place.rating, count: catalog.reviewCount)),
    const SizedBox(height: 26),
    KeyedSubtree(
      key: _sectionKeys[_Section.about],
      child: _inset(const _SectionHeader(title: 'О салоне')),
    ),
    const SizedBox(height: 12),
    _inset(_About(place: _place, open: open, onMap: _openMap)),
  ];
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.place,
    required this.photos,
    required this.index,
    required this.onChanged,
    required this.onTap,
  });

  final Place place;
  final List<String> photos;
  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return SalonPhoto(place: place);
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onTap,
          child: PageView.builder(
            key: const Key('salon-hero'),
            itemCount: photos.length,
            onPageChanged: onChanged,
            // Keeps the salon sign in the photo clear of the top buttons.
            itemBuilder: (_, index) => Image.asset(
              photos[index],
              fit: BoxFit.cover,
              alignment: const Alignment(0.5, 0),
            ),
          ),
        ),
        Positioned(
          right: 10,
          bottom: 34,
          child: IgnorePointer(
            child: Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${index + 1}/${photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.collapsed,
    required this.favorite,
    required this.onBack,
    required this.onShare,
    required this.onFavorite,
  });

  final String title;
  final bool collapsed;
  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.fromLTRB(16, math.max(top - 14, 8), 16, 8),
      decoration: BoxDecoration(
        color: collapsed ? Colors.white : Colors.transparent,
        boxShadow: [
          if (collapsed)
            const BoxShadow(
              color: Color(0x142B1430),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          _RoundButton(
            key: const Key('salon-back'),
            size: 38,
            onTap: onBack,
            child: const Icon(Icons.arrow_back_rounded, color: _ink, size: 21),
          ),
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: collapsed ? 1 : 0,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _RoundButton(
            key: const Key('salon-share'),
            size: 34,
            onTap: onShare,
            child: const Icon(Icons.ios_share_rounded, color: _ink, size: 18),
          ),
          const SizedBox(width: 8),
          _RoundButton(
            key: const Key('salon-favorite'),
            size: 34,
            onTap: onFavorite,
            child: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _pinkText,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.onTap,
    required this.child,
    super.key,
  });

  final double size;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 2,
    shadowColor: const Color(0x332B1430),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: Center(child: child),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.place,
    required this.catalog,
    required this.open,
    required this.onMap,
    required this.onCredits,
  });

  final Place place;
  final SalonCatalog? catalog;
  final bool open;
  final VoidCallback onMap;
  final VoidCallback onCredits;

  @override
  Widget build(BuildContext context) {
    final catalog = this.catalog;
    const muted = TextStyle(color: _muted, fontSize: 13.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (place.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Icon(
                            Icons.verified,
                            color: _pinkText,
                            size: 19,
                          ),
                        ),
                    ],
                  ),
                  if (catalog != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      catalog.services.take(3).map((s) => s.name).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: _star, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (catalog != null)
                        Flexible(
                          child: Text(
                            '  (${catalog.reviewCount} '
                            '${_plural(catalog.reviewCount, 'отзыв', 'отзыва', 'отзывов')})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 4),
                _Pill(
                  key: const Key('salon-credits'),
                  color: const Color(0xFFFCF4DC),
                  onTap: onCredits,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CustomPaint(
                        size: Size(15, 12),
                        painter: _CrownPainter(),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${SalonPreviewCatalog.demoCreditBalance} '
                        '${_plural(SalonPreviewCatalog.demoCreditBalance, 'кредит', 'кредита', 'кредитов')}',
                        style: const TextStyle(
                          color: Color(0xFF8B6B2E),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (catalog != null) ...[
                  const SizedBox(height: 14),
                  _Pill(
                    height: 26,
                    color: open
                        ? const Color(0xFFE3F5EE)
                        : const Color(0xFFF1F0F5),
                    child: Text(
                      open
                          ? 'Открыто до ${_hour(_closesAt)}'
                          : 'Откроется в ${_hour(_opensAt)}',
                      style: TextStyle(
                        color: open ? const Color(0xFF1E4A3D) : _muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: _muted, size: 17),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                _addressLine(place.address),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
            const SizedBox(width: 8),
            _Pill(
              key: const Key('salon-map'),
              color: const Color(0xFFFFEEF8),
              border: const Color(0xFFFAD6EA),
              onTap: onMap,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'На карте',
                    style: TextStyle(
                      color: _pinkText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: _pinkText, size: 15),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.child,
    this.border,
    this.height = 24,
    this.onTap,
    super.key,
  });

  final Color color;
  final Color? border;
  final double height;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
        border: border == null ? null : Border.all(color: border!, width: 0.8),
      ),
      child: Center(widthFactor: 1, child: child),
    ),
  );
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = const Color(0xFFE49201);
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, h * 0.2)
          ..lineTo(w * 0.3, h * 0.5)
          ..lineTo(w * 0.5, 0)
          ..lineTo(w * 0.7, h * 0.5)
          ..lineTo(w, h * 0.2)
          ..lineTo(w * 0.88, h * 0.78)
          ..lineTo(w * 0.12, h * 0.78)
          ..close(),
        paint,
      )
      ..drawRRect(
        RRect.fromLTRBR(
          w * 0.12,
          h * 0.86,
          w * 0.88,
          h,
          const Radius.circular(1),
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => false;
}

class _Amenities extends StatelessWidget {
  const _Amenities();

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (index, (icon, label, flex)) in _amenities.indexed)
        Expanded(
          flex: flex,
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                children: [
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: _softPink,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: icon == null
                          ? const _ParkingIcon()
                          : Icon(icon, color: _pinkText, size: 21),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Labels may run into the gap, as in the design.
                  SizedBox(
                    height: 26,
                    child: OverflowBox(
                      maxWidth: constraints.maxWidth + 4,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF55525E),
                            fontSize: 10,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _ParkingIcon extends StatelessWidget {
  const _ParkingIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      border: Border.all(color: _pinkText, width: 1.7),
      borderRadius: BorderRadius.circular(5),
    ),
    child: const Center(
      child: Text(
        'P',
        style: TextStyle(
          color: _pinkText,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelected});

  final _Section selected;
  final ValueChanged<_Section> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, section) in _Section.values.indexed)
        Expanded(
          flex: const [22, 23, 21, 22][index],
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 7),
            child: GestureDetector(
              key: Key('salon-tab-${section.name}'),
              onTap: () => onSelected(section),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 32,
                decoration: BoxDecoration(
                  gradient: section == selected
                      ? const LinearGradient(
                          colors: [Color(0xFFE557B5), Color(0xFFD8409F)],
                        )
                      : null,
                  color: section == selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: section == selected ? null : Border.all(color: _line),
                  boxShadow: [
                    if (section == selected)
                      const BoxShadow(
                        color: Color(0x33DF4CAE),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      section.label,
                      style: TextStyle(
                        color: section == selected ? Colors.white : _ink,
                        fontSize: 13,
                        fontWeight: section == selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
      ),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                action!,
                style: const TextStyle(
                  color: _pinkText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: _pinkText,
                size: 19,
              ),
            ],
          ),
        ),
    ],
  );
}

class _ServiceList extends StatelessWidget {
  const _ServiceList({required this.services, required this.onSelected});

  final List<SalonService> services;
  final ValueChanged<SalonService> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 158,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      itemCount: services.length,
      separatorBuilder: (_, __) => const SizedBox(width: 9),
      itemBuilder: (context, index) => _ServiceCard(
        service: services[index],
        onTap: () => onSelected(services[index]),
      ),
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final SalonService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    width: 112,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F2B1430),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      textStyle: _cardTextStyle(context),
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('salon-service-${service.id}'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 62,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(ServicePhoto.of(service), fit: BoxFit.cover),
                  const Positioned(
                    top: 5,
                    right: 6,
                    child: Icon(
                      Icons.favorite_border_rounded,
                      color: Colors.white,
                      size: 20,
                      shadows: [
                        Shadow(color: Color(0x55000000), blurRadius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 28,
                    child: Text(
                      service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: _muted,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${service.durationMinutes} мин',
                        style: const TextStyle(color: _muted, fontSize: 10.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _sum(service.price),
                            style: const TextStyle(
                              color: _pinkText,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        key: Key('salon-service-add-${service.id}'),
                        width: 23,
                        height: 23,
                        decoration: const BoxDecoration(
                          color: _pink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 17,
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

class _MasterAvatar extends StatelessWidget {
  const _MasterAvatar({
    required this.specialist,
    required this.size,
    this.available = false,
  });

  final SalonSpecialist specialist;
  final double size;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final photo = specialist.photoAsset;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF3B9DD), width: 1.4),
            ),
            child: ClipOval(
              child: photo == null
                  ? ColoredBox(
                      color: _softPink,
                      child: Center(
                        child: Text(
                          specialist.name.characters.first,
                          style: TextStyle(
                            color: _pinkText,
                            fontSize: size * 0.36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Image.asset(
                      photo,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          if (available)
            Positioned(
              right: size * 0.03,
              bottom: size * 0.07,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF19B045),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _specialties(SalonCatalog catalog, SalonSpecialist specialist) => catalog
    .services
    .where((service) => specialist.serviceIds.contains(service.id))
    .map((service) => service.name)
    .join(' · ');

class _MasterList extends StatelessWidget {
  const _MasterList({required this.catalog, required this.onSelected});

  final SalonCatalog catalog;
  final ValueChanged<SalonSpecialist> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = SalonPreviewCatalog.bookingDates(DateTime.now()).first;
    return SizedBox(
      height: 118,
      child: LayoutBuilder(
        // Four masters per screen width, like the design.
        builder: (context, constraints) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemExtent: (constraints.maxWidth - 20) / 4,
          itemCount: catalog.specialists.length,
          itemBuilder: (context, index) {
            final specialist = catalog.specialists[index];
            return GestureDetector(
              key: Key('salon-master-${specialist.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(specialist),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    _MasterAvatar(
                      specialist: specialist,
                      size: 62,
                      available: SalonPreviewCatalog.slotsFor(
                        specialist,
                        today,
                      ).isNotEmpty,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      specialist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _specialties(catalog, specialist),
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: _star, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          specialist.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MastersSheet extends StatelessWidget {
  const _MastersSheet({required this.catalog, required this.onSelected});

  final SalonCatalog catalog;
  final ValueChanged<SalonSpecialist> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        children: [
          const Text(
            'Мастера салона',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final specialist in catalog.specialists)
            InkWell(
              key: Key('salon-sheet-master-${specialist.id}'),
              onTap: () => onSelected(specialist),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _MasterAvatar(specialist: specialist, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialist.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${specialist.role} · ${_specialties(catalog, specialist)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: _star, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      specialist.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, color: _muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _GalleryRow extends StatelessWidget {
  const _GalleryRow({required this.photos, required this.onSelected});

  final List<String> photos;
  final ValueChanged<int> onSelected;

  static const _visible = 5;

  @override
  Widget build(BuildContext context) {
    final shown = math.min(photos.length, _visible);
    final hidden = photos.length - shown;
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          for (var index = 0; index < shown; index++)
            Expanded(
              flex: index == 0 ? 3 : 2,
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                child: GestureDetector(
                  key: Key('salon-photo-$index'),
                  onTap: () => onSelected(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(photos[index], fit: BoxFit.cover),
                        if (hidden > 0 && index == shown - 1)
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.5),
                            child: Center(
                              child: Text(
                                '+${hidden + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 13});

  final num rating;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 0; index < 5; index++)
        Icon(
          Icons.star_rounded,
          size: size,
          color: index < rating.round() ? _star : _line,
        ),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F2B1430),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Stars(rating: rating, size: 16),
                  const SizedBox(height: 3),
                  Text(
                    '$count ${_plural(count, 'отзыв', 'отзыва', 'отзывов')}',
                    style: const TextStyle(color: _muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        for (final (author, stars, date, service, text) in _demoReviews) ...[
          const Divider(height: 26, color: _line),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: _softPink,
                child: Text(
                  author.characters.first,
                  style: const TextStyle(
                    color: _pinkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          date,
                          style: const TextStyle(color: _muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _Stars(rating: stars, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          service,
                          style: const TextStyle(color: _muted, fontSize: 11.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Color(0xFF3D3B45),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _About extends StatelessWidget {
  const _About({required this.place, required this.open, required this.onMap});

  final Place place;
  final bool open;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      children: [
        _AboutRow(
          icon: Icons.location_on_outlined,
          title: place.address,
          subtitle: 'Адрес',
          action: 'Маршрут',
          onAction: onMap,
        ),
        const Divider(height: 22, color: _line),
        _AboutRow(
          icon: Icons.schedule_rounded,
          title: 'Ежедневно ${_hour(_opensAt)}–${_hour(_closesAt)}',
          subtitle: open ? 'Сейчас открыто' : 'Сейчас закрыто',
        ),
        if (place.isVerified) ...[
          const Divider(height: 22, color: _line),
          const _AboutRow(
            icon: Icons.verified_outlined,
            title: 'Проверенный салон',
            subtitle: 'Документы и мастера проверены Cosmetic Map',
          ),
        ],
      ],
    ),
  );
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _softPink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: _pinkText, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
      ),
      if (action != null)
        _Pill(
          color: const Color(0xFFFFEEF8),
          height: 28,
          onTap: onAction,
          child: Text(
            action!,
            style: const TextStyle(
              color: _pinkText,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ],
  );
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({required this.onCall, required this.onBook});

  final VoidCallback onCall;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      14,
      8,
      14,
      MediaQuery.paddingOf(context).bottom + 6,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFFCFCFE),
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      boxShadow: [
        BoxShadow(
          color: Color(0x122B1430),
          blurRadius: 18,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SizedBox(
      height: 50,
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: const Color(0x332B1430),
              borderRadius: BorderRadius.circular(14),
              textStyle: _cardTextStyle(context),
              child: InkWell(
                key: const Key('salon-call'),
                borderRadius: BorderRadius.circular(14),
                onTap: onCall,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_rounded, color: _ink, size: 21),
                    SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Позвонить',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD02E93), Color(0xFFC21F86)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40C8218A),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                textStyle: _cardTextStyle(context),
                child: InkWell(
                  key: const Key('salon-book'),
                  borderRadius: BorderRadius.circular(15),
                  onTap: onBook,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: Colors.white,
                                size: 21,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Записаться',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          // Appointments can be changed until 30 minutes
                          // before the visit (Appointment.canManage).
                          Text(
                            'Отмена и перенос — до 30 мин до визита',
                            style: TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GalleryPage extends StatefulWidget {
  const _GalleryPage({required this.photos, required this.initialIndex});

  final List<String> photos;
  final int initialIndex;

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  late final _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (_, index) => InteractiveViewer(
              child: Center(
                child: Image.asset(widget.photos[index], fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('salon-gallery-close'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1}/${widget.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
