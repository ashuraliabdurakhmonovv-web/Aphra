import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pink = Color(0xFFCC1F8D);
const _removedNotificationsKey = 'notifications.removed_ids';
const _ink = Color(0xFF111318);
const _muted = Color(0xFF777780);

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static final List<_NotificationItem> _sessionItems = [
    _NotificationItem(
      id: 'booking-confirmed',
      group: 'today',
      title: 'booking_confirmed_title',
      message: 'booking_confirmed_body',
      time: '11:24',
      icon: Icons.event_available_rounded,
      route: '/profile/appointments',
      unread: true,
    ),
    _NotificationItem(
      id: 'booking-changed',
      group: 'today',
      title: 'booking_changed_title',
      message: 'booking_changed_body',
      time: '09:17',
      icon: Icons.notifications_active_outlined,
      route: '/profile/appointments',
    ),
    _NotificationItem(
      id: 'payment-success',
      group: 'yesterday',
      title: 'payment_success_title',
      message: 'payment_success_body',
      time: '18:32',
      icon: Icons.credit_card_rounded,
      route: '/profile/payments',
    ),
    _NotificationItem(
      id: 'bonus-awarded',
      group: 'yesterday',
      title: 'bonus_awarded_title',
      message: 'bonus_awarded_body',
      time: '12:08',
      icon: Icons.card_giftcard_rounded,
      route: '/profile/bonuses',
    ),
    _NotificationItem(
      id: 'booking-reminder',
      group: 'october_10',
      title: 'booking_reminder_title',
      message: 'booking_reminder_body',
      time: '10:00',
      icon: Icons.calendar_month_rounded,
      route: '/profile/appointments',
    ),
  ];

  late final List<_NotificationItem> _items = _sessionItems;

  @override
  void initState() {
    super.initState();
    _restoreDismissedNotifications();
  }

  Future<void> _restoreDismissedNotifications() async {
    final preferences = await SharedPreferences.getInstance();
    final removedIds = preferences.getStringList(_removedNotificationsKey);
    if (!mounted || removedIds == null || removedIds.isEmpty) return;
    setState(() => _items.removeWhere((item) => removedIds.contains(item.id)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF9FC),
    body: Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFAFC), Color(0xFFFFF5F9)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: -76,
          width: 260,
          height: 250,
          child: IgnorePointer(
            child: Opacity(
              opacity: .62,
              child: Image.asset(
                'assets/images/notifications/pink_lily.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (_items.isEmpty)
          Positioned(
            left: -88,
            bottom: 54,
            width: 220,
            height: 210,
            child: IgnorePointer(
              child: Opacity(
                opacity: .48,
                child: Transform.rotate(
                  angle: math.pi,
                  child: Image.asset(
                    'assets/images/notifications/pink_lily.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _NotificationsHeader(onBack: context.pop),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _items.isEmpty
                      ? const _EmptyNotifications(key: ValueKey('empty'))
                      : _NotificationFeed(
                          key: const ValueKey('feed'),
                          items: _items,
                          onOpen: _openNotification,
                          onDismiss: _dismissNotification,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _openNotification(_NotificationItem item) {
    setState(() => item.unread = false);
    context.push(item.route);
  }

  Future<void> _dismissNotification(_NotificationItem item) async {
    setState(
      () => _items.removeWhere((notification) => notification.id == item.id),
    );
    final preferences = await SharedPreferences.getInstance();
    final removedIds =
        preferences.getStringList(_removedNotificationsKey) ?? [];
    if (!removedIds.contains(item.id)) {
      await preferences.setStringList(_removedNotificationsKey, [
        ...removedIds,
        item.id,
      ]);
    }
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'notifications_feed.back'.tr(),
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left_rounded, size: 34),
          ),
        ),
        Text(
          'notifications_feed.title'.tr(),
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _NotificationFeed extends StatelessWidget {
  const _NotificationFeed({
    required this.items,
    required this.onOpen,
    required this.onDismiss,
    super.key,
  });

  final List<_NotificationItem> items;
  final ValueChanged<_NotificationItem> onOpen;
  final ValueChanged<_NotificationItem> onDismiss;

  @override
  Widget build(BuildContext context) {
    const groups = ['today', 'yesterday', 'october_10'];
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 132),
      children: [
        for (final group in groups)
          if (items.any((item) => item.group == group)) ...[
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12, top: 4),
              child: Text(
                'notifications_feed.$group'.tr(),
                style: const TextStyle(
                  color: Color(0xFF777780),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            for (final item in items.where((item) => item.group == group))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  dismissThresholds: const {DismissDirection.endToStart: .34},
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: _pink,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  onDismissed: (_) => onDismiss(item),
                  child: _NotificationCard(
                    item: item,
                    onTap: () => onOpen(item),
                  ),
                ),
              ),
          ],
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: item.unread ? const Color(0xFFFCE8F2) : Colors.white,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF8E1ED),
                borderRadius: BorderRadius.circular(19),
              ),
              child: Icon(item.icon, color: _pink, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'notifications_feed.${item.title}'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 15.5,
                            height: 1.18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.time,
                        style: const TextStyle(
                          color: Color(0xFF85858D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'notifications_feed.${item.message}'.tr(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF676770),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF85858D),
              size: 25,
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 116),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/notifications/empty_bell.png',
            width: 236,
            height: 236,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'notifications_feed.empty_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: Text(
              'notifications_feed.empty_body'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF85858D),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.group,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.route,
    this.unread = false,
  });

  final String id;
  final String group;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final String route;
  bool unread;
}
