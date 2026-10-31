import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF0B0E14);
const _line = Color(0xFFEAE8EF);

/// Opens the search tab, optionally with a service filter chip selected.
void openSearch(BuildContext context, [String? category]) => context.go(
  category == null
      ? '/search'
      : Uri(
          path: '/search',
          queryParameters: {'category': category},
        ).toString(),
);

/// City, favorites and notifications row at the top of the main tabs.
class HomeCityBar extends StatelessWidget {
  const HomeCityBar({
    this.keyPrefix = 'home',
    this.showCity = true,
    this.leading,
    super.key,
  });

  final String keyPrefix;

  /// False keeps only the favorites and notifications buttons.
  final bool showCity;

  /// Optional content at the left of the actions, such as a page title.
  final Widget? leading;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: [
        if (leading != null)
          // Takes the free width and shrinks when the actions need room.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: leading,
            ),
          )
        else if (showCity)
          InkWell(
            key: Key('$keyPrefix-city'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text('home.city_only'.tr()))),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, color: _pink, size: 25),
                  const SizedBox(width: 6),
                  Text(
                    'home.city'.tr(),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _pink,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        if (leading == null) const Spacer(),
        IconButton(
          key: Key('$keyPrefix-favorites'),
          onPressed: () => context.push('/favorites'),
          icon: const Icon(
            Icons.favorite_border_rounded,
            color: _ink,
            size: 26,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          key: Key('$keyPrefix-notifications'),
          onPressed: () => context.go('/profile/notifications'),
          icon: const Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_none_rounded, color: _ink, size: 27),
              Positioned(
                right: 1,
                top: 0,
                child: SizedBox.square(
                  dimension: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFD40E73),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Search field and filter button; both open the search tab.
class HomeSearchRow extends StatelessWidget {
  const HomeSearchRow({this.keyPrefix = 'home', super.key});

  final String keyPrefix;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Material(
            color: Colors.white,
            shape: const StadiumBorder(side: BorderSide(color: _line)),
            child: InkWell(
              key: Key('$keyPrefix-search'),
              customBorder: const StadiumBorder(),
              onTap: () => openSearch(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: _ink, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'home.search_hint'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9C9AA3),
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: _line)),
          child: InkWell(
            key: Key('$keyPrefix-filters'),
            customBorder: const CircleBorder(),
            onTap: () => openSearch(context),
            child: const SizedBox.square(
              dimension: 44,
              child: Icon(Icons.tune_rounded, color: _ink, size: 21),
            ),
          ),
        ),
      ],
    ),
  );
}
