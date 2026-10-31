import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../../domain/entities/place.dart';
import '../bloc/explore_bloc.dart';
import '../widgets/places_map.dart';
import '../widgets/salon_photo.dart';
import 'salon_details_page.dart';

/// Salon map controls are rendered over the native map while its tiles load.
class ExplorePage extends StatefulWidget {
  const ExplorePage({this.category, super.key});

  /// Selected service filter from the `category` query parameter, so the home
  /// page shortcuts can open the map already filtered.
  final String? category;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  double _minimumRating = 0;
  bool _verifiedOnly = false;

  String get _category => widget.category ?? 'Все';

  void _selectCategory(String category) => context.go(
    category == 'Все'
        ? '/search'
        : Uri(
            path: '/search',
            queryParameters: {'category': category},
          ).toString(),
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    child: BlocBuilder<ExploreBloc, ExploreState>(
      builder: (context, state) {
        final places = state.maybeWhen(
          success: (places) => places,
          orElse: () => const <Place>[],
        );
        final visiblePlaces = places
            .where(_matchesFilters)
            .toList(growable: false);

        return Stack(
          fit: StackFit.expand,
          children: [
            PlacesMap(
              places: visiblePlaces,
              onPlaceSelected: (place) => _showSalon(context, place),
            ),
            _MapHeader(
              category: _category,
              onCategoryChanged: _selectCategory,
              onFiltersPressed: () => _openFilters(context),
            ),
            Positioned(
              right: AppSpacing.lg,
              bottom: 106,
              child: _RoundAction(
                icon: Icons.my_location_rounded,
                iconColor: const Color(0xFFF0009A),
                onPressed: () {},
              ),
            ),
            if (state.maybeWhen(loading: () => true, orElse: () => false))
              const Positioned(
                top: 318,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );

  bool _matchesFilters(Place place) {
    if (place.rating < _minimumRating || (_verifiedOnly && !place.isVerified)) {
      return false;
    }
    return _category == 'Все' || _belongsToCategory(place, _category);
  }

  bool _belongsToCategory(Place place, String category) {
    // Demo locations have no service field yet. Their category is only used
    // for testing the interaction; real data needs a services/category field
    // from the API to filter by service.
    const demoCategories = {
      -1: 'Маникюр',
      -2: 'Стрижки',
      -3: 'Педикюр',
      -4: 'Брови',
    };
    return demoCategories[place.id] == category ||
        '${place.name} ${place.address}'.toLowerCase().contains(
          category.toLowerCase(),
        );
  }

  Future<void> _openFilters(BuildContext context) async {
    var rating = _minimumRating;
    var verifiedOnly = _verifiedOnly;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фильтры',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                Text('Рейтинг от ${rating.toStringAsFixed(1)}'),
                Slider(
                  value: rating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  activeColor: const Color(0xFFE9009A),
                  onChanged: (value) => setSheetState(() => rating = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Только проверенные салоны'),
                  value: verifiedOnly,
                  activeThumbColor: const Color(0xFFE9009A),
                  onChanged: (value) =>
                      setSheetState(() => verifiedOnly = value),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE9009A),
                    ),
                    onPressed: () {
                      setState(() {
                        _minimumRating = rating;
                        _verifiedOnly = verifiedOnly;
                      });
                      Navigator.pop(sheetContext);
                    },
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSalon(BuildContext context, Place place) =>
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (sheetContext) => _SalonDetailsSheet(
          place: place,
          onBook: () {
            final navigator = Navigator.of(context, rootNavigator: true);
            Navigator.pop(sheetContext);
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => SalonDetailsPage(place: place),
              ),
            );
          },
          onRoute: () {
            Navigator.pop(sheetContext);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Маршрут до ${place.name}')));
          },
        ),
      );
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.category,
    required this.onCategoryChanged,
    required this.onFiltersPressed,
  });

  final String category;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onFiltersPressed;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const _TitleCard(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _RoundAction(
                      icon: Icons.tune_rounded,
                      onPressed: onFiltersPressed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _MapCategories(selected: category, onSelected: onCategoryChanged),
        ],
      ),
    ),
  );
}

class _TitleCard extends StatelessWidget {
  const _TitleCard();

  @override
  Widget build(BuildContext context) => Container(
    width: 254,
    height: 68,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(32),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xE8FFF9FC), Color(0xDAFFF0F8), Color(0xE4FFF9FC)],
      ),
      boxShadow: const [
        BoxShadow(color: Color(0x5CFFB6DC), blurRadius: 25, spreadRadius: 4),
      ],
    ),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Салоны рядом',
          style: TextStyle(
            color: Color(0xFF101827),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -.4,
          ),
        ),
        SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ташкент',
              style: TextStyle(
                color: Color(0xFF778398),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFFF04A9B),
              size: 20,
            ),
          ],
        ),
      ],
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onPressed,
    this.iconColor = const Color(0xFF11151E),
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 5,
    shadowColor: const Color(0x1AEB78B5),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onPressed,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(icon, size: 25, color: iconColor),
      ),
    ),
  );
}

class _MapCategories extends StatelessWidget {
  const _MapCategories({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        const labels = [
          'Все',
          'Маникюр',
          'Педикюр',
          'Брови',
          'Стрижки',
          'Макияж',
        ];
        final label = labels[index];
        final isSelected = label == selected;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(label),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE9009A) : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF252B35),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _SalonDetailsSheet extends StatelessWidget {
  const _SalonDetailsSheet({
    required this.place,
    required this.onBook,
    required this.onRoute,
  });

  final Place place;
  final VoidCallback onBook;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      20,
      10,
      20,
      20 + MediaQuery.viewPaddingOf(context).bottom,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD7D9DF),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 104,
                height: 104,
                child: SalonPhoto(place: place),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF141924),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF0009A),
                        size: 21,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        ' · рейтинг салона',
                        style: TextStyle(
                          color: Color(0xFF737B89),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF4B5565),
                        size: 19,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF737B89),
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.favorite_border_rounded, size: 27),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRoute,
                icon: const Icon(Icons.navigation_outlined),
                label: const Text('Маршрут'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF0009A),
                  side: const BorderSide(color: Color(0xFFFFB9DF)),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onBook,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFF0009A),
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Записаться'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
