import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/registration_profile.dart';
import '../../../favorites/presentation/favorites.dart';
import '../bloc/profile_bloc.dart';

const _pink = Color(0xFFE60093);
const _ink = Color(0xFF101827);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocConsumer<ProfileBloc, ProfileState>(
    listenWhen: (a, b) => a.status != b.status,
    listener: (context, state) {
      if (state.status == ProfileStatus.saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile.saved'.tr())));
      }
    },
    builder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFFFFBFD),
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 124),
          children: [
            const _TopActions(),
            const SizedBox(height: 14),
            _Identity(profile: state.profile),
            const SizedBox(height: 18),
            const _Stats(),
            const SizedBox(height: 18),
            const _PremiumCard(),
            const SizedBox(height: 12),
            const _MenuGrid(),
            const SizedBox(height: 22),
            const _RecentAppointments(),
          ],
        ),
      ),
    ),
  );
}

class _TopActions extends StatelessWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _CircleButton(
        icon: Icons.hexagon_outlined,
        onTap: () => context.push('/profile/settings'),
      ),
      Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CircleButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push('/profile/notifications'),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _pink,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          _CircleButton(
            icon: Icons.qr_code_scanner_rounded,
            onTap: () => context.push('/profile/qr'),
          ),
        ],
      ),
    ],
  );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Icon(icon, size: 27, color: _ink),
      ),
    ),
  );
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile});
  final RegistrationProfile? profile;

  @override
  Widget build(BuildContext context) {
    final name = profile == null
        ? 'Wazow'
        : '${profile!.firstName} ${profile!.lastName}'.trim();
    return Column(
      children: [
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_pink, Color(0xFFB74EF0)],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      backgroundImage: AssetImage(
                        'assets/images/profile/avatar.png',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 1,
                  bottom: 7,
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DD45B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 27,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.auto_awesome, color: _pink, size: 22),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile?.phone ?? '+998 90 123 45 67',
                    style: const TextStyle(fontSize: 16, color: _ink),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE6F3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          color: _pink,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'profile.regular_client'.tr(),
                          style: const TextStyle(
                            color: _pink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Favorites.shared.changes,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final items = [
      (
        Icons.calendar_month_outlined,
        '28',
        'profile.appointments',
        '/profile/appointments',
      ),
      (
        Icons.favorite_border_rounded,
        '${Favorites.shared.count}',
        'profile.favorites_count',
        '/favorites',
      ),
      (
        Icons.star_border_rounded,
        '1 900',
        'profile.bonus_points',
        '/profile/bonuses',
      ),
      (
        Icons.account_balance_wallet_outlined,
        '86',
        'profile.credits',
        '/profile/payments',
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
              child: Material(
                color: const Color(0xFFFFF3F9),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push(items[i].$4),
                  child: SizedBox(
                    height: 114,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i].$1, color: _pink, size: 30),
                        const SizedBox(height: 6),
                        Text(
                          items[i].$2,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          items[i].$3.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7E8798),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(22),
    onTap: () => context.push('/profile/premium'),
    child: Ink(
      height: 154,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEF7), Color(0xFFFFD4E9)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: 2,
            top: 2,
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 86,
              color: Color(0x42E60093),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 23,
                    backgroundColor: Color(0xFFFFC44F),
                    child: Icon(Icons.workspace_premium, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'profile.your_plan'.tr(),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'profile.premium'.tr(),
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'profile.plan_until'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF9A91A3),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  value: .7,
                  minHeight: 7,
                  backgroundColor: Colors.white,
                  valueColor: AlwaysStoppedAnimation(_pink),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'profile.credits_used'.tr(),
                style: const TextStyle(color: Color(0xFF71798A), fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.calendar_month_outlined,
        'profile.my_appointments',
        '/profile/appointments',
      ),
      (
        Icons.account_balance_wallet_outlined,
        'profile.payments',
        '/profile/payments',
      ),
      (Icons.favorite_border_rounded, 'profile.favorite', '/favorites'),
      (
        Icons.chat_bubble_outline_rounded,
        'profile.reviews',
        '/profile/reviews',
      ),
      (Icons.location_on_outlined, 'profile.addresses', '/profile/addresses'),
      (Icons.card_giftcard_rounded, 'profile.bonuses', '/profile/bonuses'),
      (Icons.help_outline_rounded, 'profile.support', '/profile/support'),
      (Icons.settings_outlined, 'profile.settings', '/profile/settings'),
    ];
    Widget card(int i) => Expanded(
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => context.push(items[i].$3),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 7, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(items[i].$1, color: _pink, size: 24),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF929AA8),
                        size: 18,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    items[i].$2.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Widget row(int start) => Row(
      children: [
        card(start),
        const SizedBox(width: 8),
        card(start + 1),
        const SizedBox(width: 8),
        card(start + 2),
        const SizedBox(width: 8),
        card(start + 3),
      ],
    );

    return Column(children: [row(0), const SizedBox(height: 8), row(4)]);
  }
}

class _RecentAppointments extends StatelessWidget {
  const _RecentAppointments();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'manicure.png',
        'profile.manicure',
        'Nur Beauty · Алена',
        '12.10 · 16:30',
      ),
      ('brows.png', 'profile.brows', 'Lola Studio · Сабина', '05.10 · 14:00'),
      (
        'haircut.png',
        'profile.haircut',
        'Mira Hair · Дилноза',
        '28.09 · 10:00',
      ),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'profile.recent'.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/profile/appointments'),
              child: Text('profile.all'.tr()),
            ),
          ],
        ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
              child: InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: () => context.push('/profile/appointments'),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          'assets/images/profile/${item.$1}',
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              item.$3,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF7E8798),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              item.$4,
                              style: const TextStyle(
                                color: Color(0xFF7E8798),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F9F1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'profile.completed'.tr(),
                          style: const TextStyle(
                            color: Color(0xFF00A86B),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF929AA8),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
