import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/service_locator.dart';
import '../../../appointments/domain/entities/appointment.dart';
import '../../../appointments/domain/repositories/appointment_repository.dart';
import '../../data/datasources/salon_preview_catalog.dart';
import '../../domain/entities/place.dart';
import '../widgets/salon_photo.dart';
import '../widgets/service_photo.dart';

const _pink = Color(0xFFCE267D);
const _ink = Color(0xFF111217);
const _muted = Color(0xFF8A8C96);
const _line = Color(0xFFECEAF2);
const _softPink = Color(0xFFFCE4F0);
const _background = Color(0xFFF6F5FA);
const _star = Color(0xFFEE198D);

String _money(int amount) =>
    '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} сум';

String _plural(int count, String one, String few, String many) {
  final tens = count % 100;
  final units = count % 10;
  if (tens >= 11 && tens <= 14) return many;
  if (units == 1) return one;
  if (units >= 2 && units <= 4) return few;
  return many;
}

const _weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
const _shortMonths = [
  'Янв',
  'Фев',
  'Мар',
  'Апр',
  'Май',
  'Июн',
  'Июл',
  'Авг',
  'Сен',
  'Окт',
  'Ноя',
  'Дек',
];
const _months = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

String _dateLabel(DateTime date) {
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String _specialties(SalonCatalog catalog, SalonSpecialist specialist) => catalog
    .services
    .where((service) => specialist.serviceIds.contains(service.id))
    .map((service) => service.name)
    .join(' · ');

enum _Method {
  credits(null, 'Кредиты'),
  online(Icons.credit_card_outlined, 'Онлайн оплата'),
  atSalon(Icons.storefront_outlined, 'В салоне');

  const _Method(this.icon, this.title);

  /// Null draws the stack of coins used for credits.
  final IconData? icon;
  final String title;
}

/// Booking flow for demo salons: service → time, master and way to pay →
/// confirmation.
class SalonDetailsPage extends StatefulWidget {
  const SalonDetailsPage({
    required this.place,
    this.serviceId,
    this.specialistId,
    super.key,
  });

  final Place place;

  /// Preselected on the salon page; booking then opens on the time step.
  final String? serviceId;
  final String? specialistId;

  @override
  State<SalonDetailsPage> createState() => _SalonDetailsPageState();
}

class _SalonDetailsPageState extends State<SalonDetailsPage> {
  static const _stepTitles = ['Выбор услуги', 'Выбор времени', 'Подтверждение'];
  static const _doneStep = 2;

  late final SalonCatalog? _catalog = SalonPreviewCatalog.forPlace(
    widget.place,
  );
  late final List<DateTime> _dates = SalonPreviewCatalog.bookingDates(
    DateTime.now(),
    days: 14,
  );
  final _dateScroll = ScrollController();
  late SalonService? _service = _catalog?.services
      .where((service) => service.id == widget.serviceId)
      .firstOrNull;

  /// Null lets the salon assign any master free at the chosen time.
  late SalonSpecialist? _specialist = _service == null
      ? null
      : _catalog
            ?.specialistsFor(_service!)
            .where((specialist) => specialist.id == widget.specialistId)
            .firstOrNull;
  late int _step = _service == null ? 0 : 1;
  int _dateIndex = 0;
  String? _slot;
  _Method _method = _Method.credits;
  bool _saving = false;
  Appointment? _booking;
  SalonSpecialist? _bookedMaster;

  DateTime get _date => _dates[_dateIndex];

  /// Credit price at the chosen slot, or the daytime price before one is set.
  int get _credits => _service!.creditsAt(_slot ?? '10:00');

  bool get _creditsAffordable =>
      _credits <= SalonPreviewCatalog.demoCreditBalance;

  @override
  void dispose() {
    _dateScroll.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_saving) return;
    if (_step == 1) {
      setState(() => _step = 0);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _selectService(SalonCatalog catalog, SalonService service) =>
      setState(() {
        if (_service?.id != service.id) {
          if (_specialist?.serviceIds.contains(service.id) != true) {
            _specialist = null;
          }
          _slot = null;
        }
        _service = service;
        _step = 1;
      });

  List<String> _slots(SalonCatalog catalog) {
    if (_specialist != null) {
      return SalonPreviewCatalog.slotsFor(_specialist!, _date);
    }
    return {
      for (final specialist in catalog.specialistsFor(_service!))
        ...SalonPreviewCatalog.slotsFor(specialist, _date),
    }.toList()..sort();
  }

  bool _isFree(SalonSpecialist specialist) {
    final slots = SalonPreviewCatalog.slotsFor(specialist, _date);
    return _slot == null ? slots.isNotEmpty : slots.contains(_slot);
  }

  void _selectSpecialist(SalonSpecialist? specialist) => setState(() {
    _specialist = specialist;
    if (specialist != null && !_isFree(specialist)) _slot = null;
  });

  void _nextWeek() {
    if (!_dateScroll.hasClients) return;
    final position = _dateScroll.position;
    final target = position.pixels + position.viewportDimension;
    _dateScroll.animateTo(
      target >= position.maxScrollExtent - 1 && position.pixels > 0
          ? 0
          : target.clamp(0.0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// "Any master" books the best-rated specialist free at the chosen slot.
  SalonSpecialist _pickSpecialist(SalonCatalog catalog) {
    if (_specialist != null) return _specialist!;
    final available =
        catalog
            .specialistsFor(_service!)
            .where(
              (specialist) => SalonPreviewCatalog.slotsFor(
                specialist,
                _date,
              ).contains(_slot),
            )
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
    return available.first;
  }

  Future<void> _confirm(SalonCatalog catalog) async {
    final service = _service!;
    final master = _pickSpecialist(catalog);
    final time = _slot!.split(':').map(int.parse).toList();
    final credits = _method == _Method.credits;
    final appointment = Appointment(
      id: 'demo-${DateTime.now().microsecondsSinceEpoch}',
      serviceName: service.name,
      salonName: widget.place.name,
      masterName: master.name,
      imageAsset: SalonPhoto.previewAssets[widget.place.id]!,
      // Slots are Tashkent local time (UTC+5).
      startsAtUtc: DateTime.utc(
        _date.year,
        _date.month,
        _date.day,
        time[0],
        time[1],
      ).subtract(const Duration(hours: 5)),
      salonUtcOffset: const Duration(hours: 5),
      durationMinutes: service.durationMinutes,
      price: credits ? _credits : service.price,
      priceIsCredits: credits,
      // No payment provider is connected yet: online payment is a test
      // prepayment treated as paid. Demo salons exist only in debug builds.
      status: AppointmentStatus.confirmed,
      canPayAtSalon: _method == _Method.atSalon,
      depositPercent: _method == _Method.online
          ? SalonService.depositPercent
          : 0,
      isDemoBooking: true,
    );
    setState(() => _saving = true);
    final result = await sl<AppointmentRepository>().createDemoBooking(
      appointment,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _saving = false;
          _slot = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${failure.message}. Выберите другое время.')),
        );
      },
      (booking) => setState(() {
        _saving = false;
        _booking = booking;
        _bookedMaster = master;
        _step = _doneStep;
      }),
    );
  }

  void _openAppointments() {
    final router = GoRouter.maybeOf(context);
    Navigator.of(context).popUntil((route) => route.settings is Page);
    router?.go('/profile/appointments');
  }

  String get _ticketNumber {
    final initials = widget.place.name
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    final day = _date.day.toString().padLeft(2, '0');
    return '#$initials-$day${_slot!.replaceAll(':', '')}';
  }

  Widget? _bottomBar(SalonCatalog catalog) {
    if (_step == 0) return null;
    if (_step == _doneStep) {
      return _ActionBar(label: 'Мои записи', onPressed: _openAppointments);
    }
    final service = _service!;
    final (label, hint) = _slot == null
        ? ('Выберите время', null)
        : _saving
        ? ('Подтверждаем…', null)
        : switch (_method) {
            _Method.credits when !_creditsAffordable => (
              'Недостаточно кредитов',
              'Выберите другой способ записи',
            ),
            _Method.credits => ('Подтвердить запись · $_credits кр.', null),
            _Method.online => (
              'Подтвердить и оплатить · ${_money(service.deposit)}',
              'Предоплата ${SalonService.depositPercent}% · тест, деньги не '
                  'списываются',
            ),
            _Method.atSalon => (
              'Подтвердить запись · ${_money(service.price)}',
              null,
            ),
          };
    final ready =
        _slot != null &&
        !_saving &&
        (_method != _Method.credits || _creditsAffordable);
    return _ActionBar(
      label: label,
      // Appointments can be changed until 30 minutes before the visit
      // (Appointment.canManage).
      hint: hint ?? 'Отмена и перенос — до 30 мин до визита',
      onPressed: ready ? () => _confirm(catalog) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    return Scaffold(
      backgroundColor: _background,
      extendBody: true,
      body: DefaultTextStyle.merge(
        style: const TextStyle(height: 1.2, color: _ink),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(
                subtitle: catalog == null
                    ? 'Запись в салон'
                    : 'Шаг ${_step + 1} из 3 · ${_stepTitles[_step]}',
                onBack: _goBack,
              ),
              Expanded(
                // The scaffold extends the body behind the bottom bar and
                // reports the bar height as bottom padding.
                child: Builder(
                  builder: (context) => ListView(
                    key: ValueKey(catalog == null ? -1 : _step),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      6,
                      16,
                      MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    children: catalog == null
                        ? [
                            _SalonCard(place: widget.place),
                            const SizedBox(height: 16),
                            const _Panel(
                              child: Text(
                                'Услуги, мастера и расписание этого салона '
                                'появятся после подключения данных салона. '
                                'Тестовую запись здесь пока создать нельзя.',
                                style: TextStyle(color: _muted, height: 1.4),
                              ),
                            ),
                          ]
                        : switch (_step) {
                            0 => _serviceStep(catalog),
                            1 => _timeStep(catalog),
                            _ => _confirmationStep(),
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: catalog == null ? null : _bottomBar(catalog),
    );
  }

  List<Widget> _serviceStep(SalonCatalog catalog) => [
    _SalonCard(place: widget.place),
    const SizedBox(height: 22),
    const _SectionTitle('Выберите услугу'),
    const SizedBox(height: 12),
    for (final service in catalog.services)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ServiceRow(
          key: Key('service-${service.id}'),
          service: service,
          selected: _service?.id == service.id,
          onTap: () => _selectService(catalog, service),
        ),
      ),
  ];

  List<Widget> _timeStep(SalonCatalog catalog) {
    final service = _service!;
    final slots = _slots(catalog);
    return [
      _ServiceSummary(
        key: const Key('booking-service-summary'),
        service: service,
        place: widget.place,
        master: _specialist?.name ?? 'Любой мастер',
        reviewCount: catalog.reviewCount,
        credits: _credits,
        onTap: _saving ? null : () => setState(() => _step = 0),
      ),
      const SizedBox(height: 22),
      _SectionTitle(
        'Выберите дату',
        action: '${_months[_date.month - 1]} ${_date.year}',
        actionColor: _muted,
        onAction: _nextWeek,
      ),
      const SizedBox(height: 12),
      _DateStrip(
        controller: _dateScroll,
        dates: _dates,
        selectedIndex: _dateIndex,
        onSelected: (index) => setState(() {
          _dateIndex = index;
          _slot = null;
        }),
      ),
      const SizedBox(height: 22),
      const _SectionTitle('Доступное время', note: 'Время указано по Ташкенту'),
      const SizedBox(height: 12),
      if (slots.isEmpty)
        const _Panel(
          child: Text(
            'На этот день свободного времени нет. Выберите другую дату.',
            style: TextStyle(color: _muted, height: 1.4),
          ),
        )
      else
        _SlotGrid(
          slots: slots,
          service: service,
          selected: _slot,
          onSelected: (slot) => setState(() => _slot = slot),
        ),
      const SizedBox(height: 24),
      _SectionTitle(
        'Выберите мастера',
        action: 'Любой мастер',
        actionKey: const Key('specialist-any'),
        actionSelected: _specialist == null,
        onAction: () => _selectSpecialist(null),
      ),
      const SizedBox(height: 12),
      _MasterStrip(
        catalog: catalog,
        specialists: catalog.specialistsFor(service),
        selected: _specialist,
        isFree: _isFree,
        onSelected: _selectSpecialist,
      ),
      const SizedBox(height: 24),
      const _SectionTitle('Способ записи'),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, method) in _Method.values.indexed) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _MethodCard(
                  key: Key('method-${method.name}'),
                  method: method,
                  selected: _method == method,
                  subtitle: switch (method) {
                    _Method.credits => TextSpan(
                      children: [
                        TextSpan(
                          text: '$_credits кр.',
                          style: TextStyle(
                            color: _creditsAffordable ? _pink : _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' · баланс '
                              '${SalonPreviewCatalog.demoCreditBalance}',
                        ),
                      ],
                    ),
                    _Method.online => const TextSpan(text: 'Карта или Click'),
                    _Method.atSalon => const TextSpan(
                      text: 'Наличными или картой',
                    ),
                  },
                  onTap: _saving
                      ? null
                      : () => setState(() => _method = method),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _confirmationStep() {
    final booking = _booking!;
    final master = _bookedMaster!;
    final (message, rows, highlight) = booking.priceIsCredits
        ? (
            'Списано ${booking.price} кр. Ваш визит в ${widget.place.name} '
                'подтверждён',
            [('Стоимость', '${booking.price} кр.')],
            ('Оплачено кредитами', null, '${booking.price} кр.'),
          )
        : booking.depositPercent > 0
        ? (
            'Предоплата получена (тест, деньги не списываются). Ваш визит в '
                '${widget.place.name} подтверждён',
            [
              ('Полная стоимость', _money(booking.price)),
              ('Осталось оплатить', _money(booking.remainingAmount)),
            ],
            (
              'Оплачено',
              '${booking.depositPercent}%',
              _money(booking.depositAmount),
            ),
          )
        : (
            'Оплата в салоне после визита. Ваш визит в ${widget.place.name} '
                'подтверждён',
            [('Полная стоимость', _money(booking.price))],
            ('К оплате в салоне', null, _money(booking.price)),
          );
    return [
      _SuccessBanner(message: message),
      const SizedBox(height: 12),
      _Panel(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                ServicePhoto.of(_service!),
                width: 76,
                height: 84,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _service!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${master.name} · ${master.role}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  _IconLine(
                    Icons.calendar_today_outlined,
                    '${_dateLabel(_date)} · $_slot',
                  ),
                  const SizedBox(height: 2),
                  _IconLine(Icons.location_on_outlined, widget.place.name),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _PaymentDetails(rows: rows, highlight: highlight),
      const SizedBox(height: 12),
      _TicketCard(
        qrData: 'cosmeticmap:booking:${booking.id}',
        number: _ticketNumber,
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.subtitle, required this.onBack});

  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
    child: Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 1.5,
          shadowColor: const Color(0x332B1430),
          child: InkWell(
            key: const Key('booking-back'),
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox.square(
              dimension: 40,
              child: Icon(Icons.arrow_back_rounded, color: _ink, size: 21),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'Запись',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
    this.title, {
    this.note,
    this.action,
    this.actionKey,
    this.actionColor = _pink,
    this.actionSelected = false,
    this.onAction,
  });

  final String title;
  final String? note;
  final String? action;
  final Key? actionKey;
  final Color actionColor;
  final bool actionSelected;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        maxLines: 1,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child: note != null
              ? Text(
                  note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 12),
                )
              : action == null
              ? null
              : GestureDetector(
                  key: actionKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          action!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: actionColor,
                            fontSize: 13.5,
                            fontWeight: actionSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        actionSelected
                            ? Icons.check_rounded
                            : Icons.chevron_right_rounded,
                        color: _pink,
                        size: 19,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D2B1430),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

/// White card that turns pink-outlined when selected.
class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.selected,
    required this.onTap,
    required this.child,
    this.radius = 14,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    textStyle: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(height: 1.2, color: _ink),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? _pink : _line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: child,
      ),
    ),
  );
}

class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _muted, size: 15),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, fontSize: 13.5),
        ),
      ),
    ],
  );
}

class _CreditChip extends StatelessWidget {
  const _CreditChip(this.credits);

  final int credits;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: _softPink,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Center(
      widthFactor: 1,
      child: Text(
        '$credits кр.',
        style: const TextStyle(
          color: _pink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _SalonCard extends StatelessWidget {
  const _SalonCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox.square(
            dimension: 68,
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: _star, size: 17),
                  const SizedBox(width: 3),
                  Text(
                    place.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _IconLine(Icons.location_on_outlined, place.address),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SalonService service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Tappable(
    selected: selected,
    onTap: onTap,
    radius: 16,
    padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            ServicePhoto.of(service),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${service.durationMinutes} мин · ${_money(service.price)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _CreditChip(service.creditsAt('10:00')),
        const Icon(Icons.chevron_right_rounded, color: _muted, size: 22),
      ],
    ),
  );
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({
    required this.service,
    required this.place,
    required this.master,
    required this.reviewCount,
    required this.credits,
    required this.onTap,
    super.key,
  });

  final SalonService service;
  final Place place;
  final String master;
  final int reviewCount;
  final int credits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Tappable(
    selected: false,
    onTap: onTap,
    radius: 18,
    padding: const EdgeInsets.all(11),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.asset(
            ServicePhoto.of(service),
            width: 66,
            height: 66,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _money(service.price),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _pink,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${place.name} · $master',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.schedule_rounded,
                              color: _muted,
                              size: 15,
                            ),
                          ),
                          TextSpan(text: ' ${service.durationMinutes} мин  '),
                          const WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Icon(
                              Icons.star_rounded,
                              color: _star,
                              size: 16,
                            ),
                          ),
                          TextSpan(
                            text: ' ${place.rating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' ($reviewCount '
                                '${_plural(reviewCount, 'отзыв', 'отзыва', 'отзывов')})',
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _CreditChip(credits),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.controller,
    required this.dates,
    required this.selectedIndex,
    required this.onSelected,
  });

  final ScrollController controller;
  final List<DateTime> dates;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _gap = 6.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: LayoutBuilder(
      // Seven days per screen width, so "next" pages by a week.
      builder: (context, constraints) => ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemExtent: (constraints.maxWidth + _gap) / 7,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final selected = index == selectedIndex;
          final secondary = TextStyle(
            color: selected ? Colors.white : _muted,
            fontSize: 12,
          );
          return Padding(
            padding: const EdgeInsets.only(right: _gap),
            child: GestureDetector(
              key: Key('date-$index'),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: selected ? _pink : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: selected ? null : Border.all(color: _line),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_weekdays[date.weekday - 1], style: secondary),
                        const SizedBox(height: 3),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected ? Colors.white : _ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(_shortMonths[date.month - 1], style: secondary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _SlotGrid extends StatelessWidget {
  const _SlotGrid({
    required this.slots,
    required this.service,
    required this.selected,
    required this.onSelected,
  });

  final List<String> slots;
  final SalonService service;
  final String? selected;
  final ValueChanged<String> onSelected;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - _gap * 3) / 4;
      return Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [
          for (final slot in slots)
            SizedBox(
              width: width,
              height: 46,
              child: _SlotTile(
                key: Key('slot-$slot'),
                slot: slot,
                credits: service.creditsAt(slot),
                selected: slot == selected,
                onTap: () => onSelected(slot),
              ),
            ),
        ],
      );
    },
  );
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({
    required this.slot,
    required this.credits,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String slot;
  final int credits;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected ? _pink : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: selected ? null : Border.all(color: _line),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot,
              style: TextStyle(
                color: selected ? Colors.white : _ink,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$credits кр.',
              style: TextStyle(
                color: selected ? Colors.white : _muted,
                fontSize: 11,
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
    this.selected = false,
    this.free = false,
  });

  final SalonSpecialist specialist;
  final double size;
  final bool selected;
  final bool free;

  @override
  Widget build(BuildContext context) {
    final photo = specialist.photoAsset;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? _pink : const Color(0xFFF3B9DD),
                width: selected ? 2 : 1.2,
              ),
            ),
            child: ClipOval(
              child: SizedBox.expand(
                child: photo == null
                    ? ColoredBox(
                        color: _softPink,
                        child: Center(
                          child: Text(
                            specialist.name.characters.first,
                            style: TextStyle(
                              color: _pink,
                              fontSize: size * 0.36,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Image.asset(photo, fit: BoxFit.cover),
              ),
            ),
          ),
          if (free)
            Positioned(
              right: size * 0.03,
              bottom: size * 0.07,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF13A240),
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

class _MasterStrip extends StatelessWidget {
  const _MasterStrip({
    required this.catalog,
    required this.specialists,
    required this.selected,
    required this.isFree,
    required this.onSelected,
  });

  final SalonCatalog catalog;
  final List<SalonSpecialist> specialists;
  final SalonSpecialist? selected;
  final bool Function(SalonSpecialist) isFree;
  final ValueChanged<SalonSpecialist> onSelected;

  static const _gap = 7.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 132,
    child: LayoutBuilder(
      // Four masters per screen width, like the design.
      builder: (context, constraints) => ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemExtent: (constraints.maxWidth + _gap) / 4,
        itemCount: specialists.length,
        itemBuilder: (context, index) {
          final specialist = specialists[index];
          final free = isFree(specialist);
          return Padding(
            padding: const EdgeInsets.only(right: _gap),
            child: Opacity(
              // Busy at the chosen time; picking them clears the time.
              opacity: free ? 1 : 0.45,
              child: _Tappable(
                key: Key('specialist-${specialist.id}'),
                selected: specialist == selected,
                onTap: () => onSelected(specialist),
                padding: const EdgeInsets.fromLTRB(4, 9, 4, 8),
                child: Column(
                  children: [
                    _MasterAvatar(
                      specialist: specialist,
                      size: 58,
                      selected: specialist == selected,
                      free: free,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      specialist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _specialties(catalog, specialist),
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.selected,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final _Method method;
  final bool selected;
  final InlineSpan subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => _Tappable(
    selected: selected,
    onTap: onTap,
    padding: const EdgeInsets.fromLTRB(10, 11, 8, 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _RadioMark(selected: selected),
            const SizedBox(width: 10),
            if (method.icon case final icon?)
              Icon(icon, color: selected ? _pink : _ink, size: 22)
            else
              CustomPaint(
                size: const Size(18, 22),
                painter: _CoinsPainter(selected ? _pink : _ink),
              ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            method.title,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 3),
        Text.rich(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, fontSize: 11, height: 1.25),
        ),
      ],
    ),
  );
}

class _CoinsPainter extends CustomPainter {
  const _CoinsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    final coin = size.height / 4;
    for (var index = 0; index < 4; index++) {
      canvas.drawRRect(
        RRect.fromLTRBR(
          1,
          1 + index * (coin - 0.6),
          size.width - 1,
          1 + index * (coin - 0.6) + coin,
          Radius.circular(coin / 2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CoinsPainter oldDelegate) => oldDelegate.color != color;
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 19,
    height: 19,
    padding: const EdgeInsets.all(3.5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? _pink : const Color(0xFFC9CBD2),
        width: 1.6,
      ),
    ),
    child: selected
        ? const DecoratedBox(
            decoration: BoxDecoration(color: _pink, shape: BoxShape.circle),
          )
        : null,
  );
}

/// Bottom panel with one wide action; its white surface also covers the
/// home-indicator inset.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.label, required this.onPressed, this.hint});

  final String label;
  final String? hint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Color(0xFFFCFBFE),
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Color(0x122B1430),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: FilledButton(
          key: const Key('booking-action'),
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: _pink,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _pink.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white,
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            shape: const StadiumBorder(),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: const TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 14, 16, 14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFCE1EF), Color(0xFFFDF0F7)],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFF8D7E9)),
    ),
    child: Row(
      children: [
        const _SuccessBadge(),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Запись подтверждена',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Check mark in a soft circle with a few confetti strokes around it.
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  static Widget _stroke(double angle) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 11,
      height: 3.5,
      decoration: BoxDecoration(
        color: _pink,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 92,
    height: 92,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFAD0E6),
          ),
          child: const Icon(Icons.check_rounded, color: _pink, size: 34),
        ),
        Positioned(left: 4, top: 12, child: _stroke(0.8)),
        Positioned(right: 8, top: 4, child: _stroke(-1.0)),
        Positioned(left: 2, bottom: 10, child: _stroke(-0.6)),
        Positioned(right: 4, bottom: 18, child: _stroke(0.6)),
      ],
    ),
  );
}

class _PaymentDetails extends StatelessWidget {
  const _PaymentDetails({required this.rows, required this.highlight});

  /// Plain label/value lines; the first goes above [highlight].
  final List<(String, String)> rows;

  /// Label, optional badge (e.g. "50%") and value of the emphasised line.
  final (String, String?, String) highlight;

  static Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15.5))),
        Text(
          value,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final (label, badge, value) = highlight;
    return _Panel(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Детали оплаты',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 4),
          _row(rows.first.$1, rows.first.$2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _pink, fontSize: 15.5),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9D2E6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: _pink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: _pink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final (label, value) in rows.skip(1)) _row(label, value),
          if (rows.length == 1) const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.qrData, required this.number});

  final String qrData;
  final String number;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Электронный билет',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF8D7E9), width: 2),
                ),
                child: QrImageView(
                  key: const Key('booking-ticket-qr'),
                  data: qrData,
                  size: 112,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Покажите этот QR-код администратору',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Билет $number',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
