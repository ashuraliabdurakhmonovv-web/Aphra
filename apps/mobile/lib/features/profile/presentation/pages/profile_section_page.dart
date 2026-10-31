import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_tokens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/platform/maps_launcher.dart';
import '../../../auth/domain/entities/registration_profile.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/profile_edit_dialog.dart';

enum ProfileSection {
  appointments,
  payments,
  reviews,
  addresses,
  bonuses,
  support,
  settings,
  notifications,
  clientQr,
  premium,
}

class ProfileSectionPage extends StatefulWidget {
  const ProfileSectionPage({required this.section, super.key});

  final ProfileSection section;

  @override
  State<ProfileSectionPage> createState() => _ProfileSectionPageState();
}

class _ProfileSectionPageState extends State<ProfileSectionPage> {
  bool appointmentNotifications = true;
  bool offerNotifications = true;
  bool newsNotifications = true;
  bool useLocation = false;
  bool darkTheme = false;
  int appointmentTab = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.section == ProfileSection.settings) {
      return _settingsScaffold(context);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFD),
      appBar: AppBar(
        title: Text(_titleKey.tr()),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFFBFD),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: _content(context),
        ),
      ),
    );
  }

  Widget _settingsScaffold(BuildContext context) {
    final profile = context.watch<ProfileBloc>().state.profile;
    final displayName = profile == null
        ? 'Нигина Абдуллаева'
        : '${profile.firstName} ${profile.lastName}'.trim();
    final phone = profile?.phone ?? '+998 90 123 45 67';
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      body: Stack(
        children: [
          const Positioned(right: -50, top: 25, child: _PinkGlow(size: 210)),
          const Positioned(left: -80, top: 420, child: _PinkGlow(size: 190)),
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 126),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _SettingsBackButton(onTap: context.pop),
                ),
                const SizedBox(height: 10),
                Text(
                  'profile.settings'.tr(),
                  style: const TextStyle(
                    fontSize: 31,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101827),
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsProfileCard(
                  name: displayName,
                  phone: phone,
                  onTap: () => _editSettingsProfile(context, profile),
                ),
                const SizedBox(height: 22),
                _SettingsLabel('profile.account'.tr()),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.person_outline_rounded,
                      title: 'profile.personal_data'.tr(),
                      onTap: () => _editSettingsProfile(context, profile),
                    ),
                    _SettingsRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'profile.security'.tr(),
                      onTap: () => _message(context, 'profile.security_ready'),
                    ),
                    _SettingsRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'profile.notifications'.tr(),
                      onTap: () => context.push('/profile/notifications'),
                    ),
                    _SettingsRow(
                      icon: Icons.credit_card_rounded,
                      title: 'profile.payment_methods'.tr(),
                      onTap: () => context.push('/profile/payments'),
                    ),
                    _SettingsRow(
                      icon: Icons.location_on_outlined,
                      title: 'profile.my_addresses'.tr(),
                      onTap: () => context.push('/profile/addresses'),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SettingsLabel('profile.app_settings'.tr()),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.language_rounded,
                      title: 'profile.language'.tr(),
                      value: 'Русский',
                      onTap: () => _showLanguagePicker(context),
                    ),
                    _SettingsRow.switcher(
                      icon: Icons.dark_mode_outlined,
                      title: 'profile.dark_theme'.tr(),
                      value: darkTheme,
                      onChanged: (value) => setState(() => darkTheme = value),
                    ),
                    _SettingsRow.switcher(
                      icon: Icons.notifications_none_rounded,
                      title: 'profile.special_offers'.tr(),
                      value: offerNotifications,
                      onChanged: (value) =>
                          setState(() => offerNotifications = value),
                    ),
                    _SettingsRow.switcher(
                      icon: Icons.mail_outline_rounded,
                      title: 'profile.tips_news'.tr(),
                      value: newsNotifications,
                      onChanged: (value) =>
                          setState(() => newsNotifications = value),
                    ),
                    _SettingsRow.switcher(
                      icon: Icons.near_me_outlined,
                      title: 'profile.use_location'.tr(),
                      value: useLocation,
                      onChanged: (value) => setState(() => useLocation = value),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SettingsLabel('profile.support'.tr()),
                const SizedBox(height: 8),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.help_outline_rounded,
                      title: 'profile.faq'.tr(),
                      onTap: () => context.push('/profile/support'),
                    ),
                    _SettingsRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'profile.contact_us'.tr(),
                      onTap: () => context.push('/profile/support'),
                    ),
                    _SettingsRow(
                      icon: Icons.gpp_good_outlined,
                      title: 'profile.legal_info'.tr(),
                      onTap: () => _message(context, 'profile.legal_ready'),
                      showDivider: false,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 58,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/auth'),
                    icon: const Icon(Icons.logout_rounded),
                    label: Text('profile.logout'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF2D85),
                      backgroundColor: const Color(0xFFFFEDF5),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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

  String get _titleKey => switch (widget.section) {
    ProfileSection.appointments => 'profile.my_appointments',
    ProfileSection.payments => 'profile.payments',
    ProfileSection.reviews => 'profile.reviews',
    ProfileSection.addresses => 'profile.addresses',
    ProfileSection.bonuses => 'profile.bonuses',
    ProfileSection.support => 'profile.support',
    ProfileSection.settings => 'profile.settings',
    ProfileSection.notifications => 'profile.notifications',
    ProfileSection.clientQr => 'profile.client_qr',
    ProfileSection.premium => 'profile.premium',
  };

  List<Widget> _content(BuildContext context) => switch (widget.section) {
    ProfileSection.appointments => _appointments(context),
    ProfileSection.payments => _payments(context),
    ProfileSection.reviews => _reviews(context),
    ProfileSection.addresses => _addresses(context),
    ProfileSection.bonuses => _bonuses(context),
    ProfileSection.support => _support(context),
    ProfileSection.settings => _settings(context),
    ProfileSection.notifications => _notificationItems(context),
    ProfileSection.clientQr => _qr(context),
    ProfileSection.premium => _premium(context),
  };

  List<Widget> _appointments(BuildContext context) => [
    _SegmentedHeader(
      first: 'profile.upcoming'.tr(),
      second: 'profile.history'.tr(),
      selected: appointmentTab,
      onChanged: (value) => setState(() => appointmentTab = value),
    ),
    const SizedBox(height: 18),
    if (appointmentTab == 0) ...[
      _SectionHeading('profile.upcoming'.tr()),
      const SizedBox(height: 10),
      _InfoCard(
        icon: Icons.content_cut_rounded,
        title: 'profile.upcoming_service'.tr(),
        subtitle: 'profile.upcoming_place'.tr(),
        trailing: '18.10\n15:30',
        actionLabel: 'profile.manage'.tr(),
      ),
    ] else ...[
      _SectionHeading('profile.history'.tr()),
      const SizedBox(height: 10),
      for (final item in [
        ('profile.manicure', 'Nur Beauty · Алена', '12.10 · 16:30'),
        ('profile.brows', 'Lola Studio · Сабина', '05.10 · 14:00'),
        ('profile.haircut', 'Mira Hair · Дилноза', '28.09 · 10:00'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _InfoCard(
            icon: Icons.check_circle_outline,
            title: item.$1.tr(),
            subtitle: item.$2,
            trailing: item.$3,
          ),
        ),
    ],
  ];

  List<Widget> _payments(BuildContext context) => [
    _BalanceCard(
      icon: Icons.account_balance_wallet_outlined,
      value: '86',
      label: 'profile.available_credits'.tr(),
    ),
    const SizedBox(height: 18),
    _PrimaryAction(
      label: 'profile.buy_credits'.tr(),
      onPressed: () => _message(context, 'profile.payment_prepared'),
    ),
    const SizedBox(height: 24),
    _SectionHeading('profile.payment_history'.tr()),
    const SizedBox(height: 10),
    _TransactionTile(
      title: 'profile.premium'.tr(),
      date: '12.10.2026',
      amount: '-14',
    ),
    _TransactionTile(
      title: 'profile.credit_topup'.tr(),
      date: '01.10.2026',
      amount: '+100',
      positive: true,
    ),
  ];

  List<Widget> _reviews(BuildContext context) => [
    _BalanceCard(
      icon: Icons.star_rounded,
      value: '4.9',
      label: 'profile.average_rating'.tr(),
    ),
    const SizedBox(height: 20),
    for (final title in ['Nur Beauty', 'Lola Studio'])
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _InfoCard(
          icon: Icons.chat_bubble_outline_rounded,
          title: title,
          subtitle: 'profile.review_sample'.tr(),
          trailing: '★★★★★',
        ),
      ),
    _PrimaryAction(
      label: 'profile.write_review'.tr(),
      onPressed: () => _message(context, 'profile.review_ready'),
    ),
  ];

  List<Widget> _addresses(BuildContext context) => [
    for (final item in [
      ('Nur Beauty', 'profile.address_one'),
      ('Lola Studio', 'profile.address_two'),
      ('Mira Hair', 'profile.address_three'),
    ])
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _InfoCard(
          icon: Icons.location_on_outlined,
          title: item.$1,
          subtitle: item.$2.tr(),
          trailing: 'profile.route'.tr(),
          onTap: () => _openRoute(context, item.$2.tr()),
        ),
      ),
  ];

  Future<void> _openRoute(BuildContext context, String address) async {
    final opened = await sl<MapsLauncher>().openDirections(
      address: '$address, Tashkent, Uzbekistan',
    );
    if (context.mounted && !opened) {
      _message(context, 'place.maps_unavailable');
    }
  }

  List<Widget> _bonuses(BuildContext context) => [
    _BalanceCard(
      icon: Icons.card_giftcard_rounded,
      value: '1 900',
      label: 'profile.bonus_points'.tr(),
    ),
    const SizedBox(height: 22),
    _SectionHeading('profile.promo_codes'.tr()),
    const SizedBox(height: 10),
    _PromoCard(
      code: 'BEAUTY20',
      description: 'profile.promo_beauty'.tr(),
      onCopy: () => _message(context, 'profile.code_copied'),
    ),
    const SizedBox(height: 10),
    _PromoCard(
      code: 'WELCOME',
      description: 'profile.promo_welcome'.tr(),
      onCopy: () => _message(context, 'profile.code_copied'),
    ),
  ];

  List<Widget> _support(BuildContext context) => [
    _InfoCard(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'profile.support_chat'.tr(),
      subtitle: 'profile.support_chat_hint'.tr(),
      onTap: () => _message(context, 'profile.chat_started'),
    ),
    const SizedBox(height: 10),
    _InfoCard(
      icon: Icons.phone_outlined,
      title: 'profile.call_support'.tr(),
      subtitle: '+998 71 200 00 00',
      onTap: () => _message(context, 'profile.call_prepared'),
    ),
    const SizedBox(height: 22),
    _SectionHeading('profile.faq'.tr()),
    const SizedBox(height: 8),
    for (final key in [
      'profile.faq_booking',
      'profile.faq_credits',
      'profile.faq_cancel',
    ])
      Card(
        child: ExpansionTile(
          title: Text(key.tr()),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [Text('profile.faq_answer'.tr())],
        ),
      ),
  ];

  List<Widget> _settings(BuildContext context) => [
    SwitchListTile.adaptive(
      value: appointmentNotifications,
      activeThumbColor: AppColors.primary,
      title: Text('profile.booking_notifications'.tr()),
      subtitle: Text('profile.booking_notifications_hint'.tr()),
      onChanged: (value) => setState(() => appointmentNotifications = value),
    ),
    SwitchListTile.adaptive(
      value: offerNotifications,
      activeThumbColor: AppColors.primary,
      title: Text('profile.offer_notifications'.tr()),
      subtitle: Text('profile.offer_notifications_hint'.tr()),
      onChanged: (value) => setState(() => offerNotifications = value),
    ),
    const Divider(height: 32),
    _InfoCard(
      icon: Icons.language_rounded,
      title: 'profile.language'.tr(),
      subtitle: 'Русский',
      onTap: () => _message(context, 'profile.language_ready'),
    ),
    const SizedBox(height: 10),
    _InfoCard(
      icon: Icons.lock_outline_rounded,
      title: 'profile.privacy'.tr(),
      subtitle: 'profile.privacy_hint'.tr(),
      onTap: () => _message(context, 'profile.privacy_ready'),
    ),
  ];

  List<Widget> _notificationItems(BuildContext context) => [
    for (final key in [
      'profile.notification_booking',
      'profile.notification_bonus',
      'profile.notification_offer',
    ])
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _InfoCard(
          icon: Icons.notifications_none_rounded,
          title: key.tr(),
          subtitle: 'profile.today'.tr(),
        ),
      ),
  ];

  List<Widget> _qr(BuildContext context) => [
    const SizedBox(height: 30),
    Center(
      child: Container(
        width: 240,
        height: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 24),
          ],
        ),
        child: const Icon(Icons.qr_code_2_rounded, size: 200),
      ),
    ),
    const SizedBox(height: 24),
    Text(
      'profile.client_qr_hint'.tr(),
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
    ),
  ];

  List<Widget> _premium(BuildContext context) => [
    const SizedBox(height: 12),
    const Icon(
      Icons.workspace_premium_rounded,
      size: 110,
      color: Color(0xFFFFB82E),
    ),
    const SizedBox(height: 10),
    Text(
      'profile.premium'.tr(),
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    Text(
      'profile.premium_full_hint'.tr(),
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
    ),
    const SizedBox(height: 24),
    for (final key in [
      'profile.premium_benefit_one',
      'profile.premium_benefit_two',
      'profile.premium_benefit_three',
    ])
      ListTile(
        leading: const Icon(Icons.check_circle, color: AppColors.primary),
        title: Text(key.tr()),
      ),
    const SizedBox(height: 18),
    _PrimaryAction(
      label: 'profile.extend_plan'.tr(),
      onPressed: () => _message(context, 'profile.plan_prepared'),
    ),
  ];

  Future<void> _editSettingsProfile(
    BuildContext context,
    RegistrationProfile? profile,
  ) async {
    final value = await showProfileEditDialog(
      context: context,
      title: 'profile.personal_data'.tr(),
      firstName: profile?.firstName ?? 'Нигина',
      lastName: profile?.lastName ?? 'Абдуллаева',
    );
    if (value == null || value.$1.isEmpty || !context.mounted) return;
    context.read<ProfileBloc>().add(
      ProfileUpdated(
        RegistrationProfile(
          phone: profile?.phone ?? '+998901234567',
          firstName: value.$1,
          lastName: value.$2,
          birthDate: profile?.birthDate ?? DateTime(2000),
          gender: profile?.gender ?? UserGender.female,
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final locale = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Русский'),
              onTap: () => Navigator.pop(sheetContext, const Locale('ru')),
            ),
            ListTile(
              title: const Text('O‘zbekcha'),
              onTap: () => Navigator.pop(sheetContext, const Locale('uz')),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.pop(sheetContext, const Locale('en')),
            ),
          ],
        ),
      ),
    );
    if (locale != null && context.mounted) await context.setLocale(locale);
  }

  void _message(BuildContext context, String key) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(key.tr())));
}

class _PinkGlow extends StatelessWidget {
  const _PinkGlow({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x45FF7CBB), Color(0x00FFF7FB)],
        ),
      ),
    ),
  );
}

class _SettingsBackButton extends StatelessWidget {
  const _SettingsBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: const SizedBox(
        width: 52,
        height: 52,
        child: Icon(Icons.arrow_back_rounded, size: 25),
      ),
    ),
  );
}

class _SettingsProfileCard extends StatelessWidget {
  const _SettingsProfileCard({
    required this.name,
    required this.phone,
    required this.onTap,
  });
  final String name;
  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .92),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const CircleAvatar(
                  radius: 44,
                  backgroundImage: AssetImage(
                    'assets/images/profile/avatar.png',
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: 3,
                  child: Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2D85),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    phone,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBE6F3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'profile.regular_client'.tr(),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(children: children),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
    this.showDivider = true,
  }) : switchValue = null,
       onChanged = null;

  const _SettingsRow.switcher({
    required this.icon,
    required this.title,
    required bool value,
    required this.onChanged,
    this.showDivider = true,
  }) : switchValue = value,
       value = null,
       onTap = null;

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Row(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF101827)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF101827),
                  ),
                ),
              ),
              if (value != null) ...[
                Text(
                  value!,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 4),
              ],
              if (switchValue != null)
                Switch.adaptive(
                  value: switchValue!,
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFFFF2D85),
                  onChanged: onChanged,
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
      if (showDivider)
        const Divider(height: 1, indent: 40, color: Color(0xFFEDE8EB)),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
  );
}

class _SegmentedHeader extends StatelessWidget {
  const _SegmentedHeader({
    required this.first,
    required this.second,
    required this.selected,
    required this.onChanged,
  });
  final String first;
  final String second;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
    segments: [
      ButtonSegment(value: 0, label: Text(first)),
      ButtonSegment(value: 1, label: Text(second)),
    ],
    selected: {selected},
    onSelectionChanged: (value) => onChanged(value.first),
    showSelectedIcon: false,
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFFEFF8), Color(0xFFFFD7EA)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          child: Icon(icon, color: AppColors.primary, size: 30),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.actionLabel,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFFBE6F3),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (actionLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    ),
  );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      FilledButton(onPressed: onPressed, child: Text(label));
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.title,
    required this.date,
    required this.amount,
    this.positive = false,
  });
  final String title;
  final String date;
  final String amount;
  final bool positive;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFFBE6F3),
      child: Icon(Icons.receipt_long_outlined, color: AppColors.primary),
    ),
    title: Text(title),
    subtitle: Text(date),
    trailing: Text(
      amount,
      style: TextStyle(
        color: positive ? AppColors.success : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.code,
    required this.description,
    required this.onCopy,
  });
  final String code;
  final String description;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(description),
            ],
          ),
        ),
        IconButton(onPressed: onCopy, icon: const Icon(Icons.copy_rounded)),
      ],
    ),
  );
}
