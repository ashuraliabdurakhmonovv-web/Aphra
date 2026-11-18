import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../../core/widgets/app_bottom_navigation.dart';
import '../../features/auth/presentation/pages/phone_auth_page.dart';
import '../../features/appointments/presentation/bloc/appointments_bloc.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/explore/presentation/bloc/explore_bloc.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/bonuses_page.dart';
import '../../features/profile/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/payments_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/profile_section_page.dart';
import '../../features/profile/presentation/pages/support_page.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

const _startRoute = String.fromEnvironment(
  'START_ROUTE',
  defaultValue: '/auth',
);

final appRouter = GoRouter(
  initialLocation: _startRoute,
  // On iOS Flutter supplies `/` as the platform route on cold start.  The app
  // owns its initial route, otherwise a requested nested route is discarded.
  overridePlatformDefaultLocation: true,
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, _) => PhoneAuthPage(
        onSkip: () => context.go('/home'),
        onCompleted: () => context.go('/home'),
      ),
    ),
    // Opened from the home page and the profile, over the tab bar.
    GoRoute(
      path: '/favorites',
      // ?tab=salons, services or masters opens that tab.
      builder: (_, state) =>
          FavoritesPage(initialTab: state.uri.queryParameters['tab']),
    ),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => _AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => BlocProvider(
                create: (_) =>
                    sl<ExploreBloc>()..add(const ExploreEvent.started()),
                child: const HomePage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (_, state) => BlocProvider(
                create: (_) =>
                    sl<ExploreBloc>()..add(const ExploreEvent.started()),
                child: ExplorePage(
                  category: state.uri.queryParameters['category'],
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/catalog',
              // Categories open the services of the salons from the data.
              // The page only reads the bloc on a tap, so it loads up front.
              builder: (_, __) => BlocProvider(
                lazy: false,
                create: (_) =>
                    sl<ExploreBloc>()..add(const ExploreEvent.started()),
                child: const CatalogPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, __) => BlocProvider(
                create: (_) => sl<ProfileBloc>()..add(const ProfileStarted()),
                child: const ProfilePage(),
              ),
              routes: [
                GoRoute(
                  path: 'appointments',
                  builder: (_, __) => BlocProvider(
                    create: (_) =>
                        sl<AppointmentsBloc>()
                          ..add(const AppointmentsStarted()),
                    child: const AppointmentsPage(),
                  ),
                ),
                GoRoute(
                  path: 'payments',
                  builder: (_, __) => const PaymentsPage(),
                ),
                GoRoute(
                  path: 'reviews',
                  builder: (_, __) =>
                      const ProfileSectionPage(section: ProfileSection.reviews),
                ),
                GoRoute(
                  path: 'addresses',
                  builder: (_, __) => const ProfileSectionPage(
                    section: ProfileSection.addresses,
                  ),
                ),
                GoRoute(
                  path: 'bonuses',
                  builder: (_, __) => const BonusesPage(),
                ),
                GoRoute(
                  path: 'support',
                  builder: (_, __) => const SupportPage(),
                ),
                GoRoute(
                  path: 'settings',
                  builder: (_, __) => BlocProvider(
                    create: (_) =>
                        sl<ProfileBloc>()..add(const ProfileStarted()),
                    child: const ProfileSectionPage(
                      section: ProfileSection.settings,
                    ),
                  ),
                ),
                GoRoute(
                  path: 'notifications',
                  builder: (_, __) => const NotificationsPage(),
                ),
                GoRoute(
                  path: 'qr',
                  builder: (_, __) => const ProfileSectionPage(
                    section: ProfileSection.clientQr,
                  ),
                ),
                GoRoute(
                  path: 'premium',
                  builder: (_, __) =>
                      const ProfileSectionPage(section: ProfileSection.premium),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBody: true,
    body: shell,
    bottomNavigationBar: AppBottomNavigation(
      currentIndex: shell.currentIndex,
      onSelected: shell.goBranch,
      items: [
        AppNavigationItem(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_outlined,
          label: 'navigation.home'.tr(),
        ),
        AppNavigationItem(
          icon: Icons.map_outlined,
          selectedIcon: Icons.map,
          label: 'navigation.map'.tr(),
        ),
        AppNavigationItem(
          icon: Icons.grid_view_outlined,
          selectedIcon: Icons.grid_view,
          label: 'navigation.catalog'.tr(),
        ),
        AppNavigationItem(
          icon: Icons.shopping_bag_outlined,
          selectedIcon: Icons.shopping_bag,
          label: 'navigation.cart'.tr(),
        ),
        AppNavigationItem(
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: 'navigation.profile'.tr(),
        ),
      ],
    ),
  );
}
