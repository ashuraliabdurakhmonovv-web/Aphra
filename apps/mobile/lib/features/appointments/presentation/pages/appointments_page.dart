import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../domain/entities/appointment.dart';
import '../bloc/appointments_bloc.dart';

const _pink = Color(0xFFEC008C);
const _ink = Color(0xFF101827);
const _background = Color(0xFFFFF9FC);

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: BlocConsumer<AppointmentsBloc, AppointmentsState>(
      listenWhen: (previous, current) =>
          previous.message != current.message ||
          previous.status != current.status,
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!.tr())));
        }
        if (state.status == AppointmentsStatus.failure &&
            state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.status == AppointmentsStatus.loading ||
            state.status == AppointmentsStatus.initial) {
          return const Center(child: CircularProgressIndicator(color: _pink));
        }
        if (state.status == AppointmentsStatus.failure &&
            state.appointments.isEmpty) {
          return AppErrorState(
            title: state.message ?? 'Unable to load appointments',
            retryLabel: 'common.retry'.tr(),
            onRetry: () => context.read<AppointmentsBloc>().add(
              const AppointmentsStarted(),
            ),
          );
        }
        return SafeArea(
          bottom: false,
          child: Stack(
            children: [
              const Positioned(top: -110, right: -80, child: _PinkGlow()),
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 126),
                children: [
                  _Header(onBack: context.pop),
                  const SizedBox(height: 20),
                  _AppointmentTabs(
                    selected: state.selectedTab,
                    onSelected: (tab) => context.read<AppointmentsBloc>().add(
                      AppointmentsTabSelected(tab),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _AppointmentList(
                      key: ValueKey(state.selectedTab),
                      state: state,
                    ),
                  ),
                ],
              ),
              if (state.status == AppointmentsStatus.working)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x11000000),
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(color: _pink),
                        ),
                      ),
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

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onBack,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.arrow_back_rounded, size: 25),
          ),
        ),
      ),
      Expanded(
        child: Text(
          'appointments.title'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      const SizedBox(width: 48),
    ],
  );
}

class _AppointmentTabs extends StatelessWidget {
  const _AppointmentTabs({required this.selected, required this.onSelected});
  final AppointmentsTab selected;
  final ValueChanged<AppointmentsTab> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFEADDE5)),
    ),
    child: Row(
      children: [
        _TabButton(
          label: 'appointments.upcoming'.tr(),
          selected: selected == AppointmentsTab.upcoming,
          onTap: () => onSelected(AppointmentsTab.upcoming),
        ),
        _TabButton(
          label: 'appointments.history'.tr(),
          selected: selected == AppointmentsTab.history,
          onTap: () => onSelected(AppointmentsTab.history),
        ),
      ],
    ),
  );
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFE5F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _pink : _ink,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    ),
  );
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({required this.state, super.key});
  final AppointmentsState state;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = state.selectedTab == AppointmentsTab.upcoming;
    final items = isUpcoming ? state.upcoming : state.history;
    final heading = isUpcoming
        ? 'appointments.upcoming'.tr()
        : 'appointments.history'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              heading,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(width: 9),
            Container(
              width: 27,
              height: 27,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE5F2),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${items.length}',
                style: const TextStyle(
                  color: _pink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          AppEmptyState(
            title: isUpcoming
                ? 'appointments.empty_upcoming'.tr()
                : 'appointments.empty_history'.tr(),
            description: 'appointments.dev_data_note'.tr(),
            icon: isUpcoming
                ? Icons.calendar_month_outlined
                : Icons.history_rounded,
          )
        else
          for (final appointment in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: _AppointmentCard(
                appointment: appointment,
                serverNowUtc: state.serverNowUtc ?? DateTime.now().toUtc(),
              ),
            ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.serverNowUtc,
  });
  final Appointment appointment;
  final DateTime serverNowUtc;

  @override
  Widget build(BuildContext context) {
    final canManage = appointment.canManage(serverNowUtc);
    final isSoon = appointment.isSoon(serverNowUtc);
    final upcoming = appointment.isUpcoming;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    appointment.imageAsset,
                    height: 82,
                    width: 82,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              appointment.serviceName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusPill(
                            status: appointment.status,
                            isSoon: isSoon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appointment.salonName} · ${appointment.masterName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF778092),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _AppointmentFacts(appointment: appointment),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: Divider(height: 1, color: Color(0xFFF0EAF0)),
            ),
            _SecondaryFacts(appointment: appointment),
            if (appointment.depositPercent > 0) ...[
              const SizedBox(height: 9),
              Text(
                'Предоплата ${appointment.depositPercent}%: ${_moneyAmount(appointment.depositAmount)} · после услуги: ${_moneyAmount(appointment.remainingAmount)}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (appointment.isDemoBooking)
                const Text(
                  'Тестовая запись · деньги не списываются',
                  style: TextStyle(color: Color(0xFF7D8797), fontSize: 11),
                ),
            ],
            if (upcoming && !canManage) ...[
              const SizedBox(height: 11),
              _VisitWarning(),
            ],
            const SizedBox(height: 12),
            _CardActions(
              appointment: appointment,
              canManage: canManage,
              isUpcoming: upcoming,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.isSoon});
  final AppointmentStatus status;
  final bool isSoon;

  @override
  Widget build(BuildContext context) {
    final (label, color, background, icon) = isSoon
        ? (
            'appointments.soon'.tr(),
            const Color(0xFFB67819),
            const Color(0xFFFFF2D8),
            Icons.timer_outlined,
          )
        : switch (status) {
            AppointmentStatus.confirmed => (
              'appointments.confirmed'.tr(),
              const Color(0xFF14934B),
              const Color(0xFFE6F8ED),
              Icons.check_circle,
            ),
            AppointmentStatus.awaitingPayment => (
              'appointments.awaiting_payment'.tr(),
              const Color(0xFFB67819),
              const Color(0xFFFFF2D8),
              Icons.credit_card_rounded,
            ),
            AppointmentStatus.completed => (
              'appointments.completed'.tr(),
              const Color(0xFF14934B),
              const Color(0xFFE6F8ED),
              Icons.check_circle,
            ),
            AppointmentStatus.cancelled => (
              'appointments.cancelled'.tr(),
              const Color(0xFFD61B5A),
              const Color(0xFFFFE5EC),
              Icons.cancel,
            ),
            AppointmentStatus.noShow => (
              'appointments.no_show'.tr(),
              const Color(0xFF7B6E78),
              const Color(0xFFF0EAEE),
              Icons.person_off_outlined,
            ),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentFacts extends StatelessWidget {
  const _AppointmentFacts({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 7,
    children: [
      _Fact(
        icon: Icons.calendar_today_outlined,
        value: _dateLabel(appointment.salonStartsAt),
      ),
      _Fact(
        icon: Icons.access_time_rounded,
        value: _timeLabel(appointment.salonStartsAt),
      ),
      _Fact(
        icon: Icons.account_balance_wallet_outlined,
        value: _priceLabel(appointment),
      ),
    ],
  );
}

class _SecondaryFacts extends StatelessWidget {
  const _SecondaryFacts({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF98A0AF)),
      const SizedBox(width: 5),
      Text(
        '${appointment.durationMinutes} ${'appointments.minutes'.tr()}',
        style: const TextStyle(color: Color(0xFF7D8797), fontSize: 12),
      ),
      const SizedBox(width: 18),
      const Icon(Icons.star_rounded, size: 18, color: _pink),
      const SizedBox(width: 4),
      const Text(
        '4.8',
        style: TextStyle(
          color: _ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 4),
      const Text(
        '(126)',
        style: TextStyle(color: Color(0xFF7D8797), fontSize: 12),
      ),
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: _pink),
      const SizedBox(width: 5),
      Text(
        value,
        style: const TextStyle(
          color: _ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _VisitWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9EE),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Color(0xFFD51D5C),
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'appointments.visit_too_soon'.tr(),
            style: const TextStyle(
              color: Color(0xFFB64B6B),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.appointment,
    required this.canManage,
    required this.isUpcoming,
  });
  final Appointment appointment;
  final bool canManage;
  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    if (isUpcoming && !canManage) {
      return _ActionButton(
        icon: Icons.info_outline_rounded,
        label: 'appointments.details'.tr(),
        outlined: true,
        onTap: () => _showDetails(context, appointment),
      );
    }
    if (isUpcoming && appointment.status == AppointmentStatus.awaitingPayment) {
      return Column(
        children: [
          _ActionButton(
            icon: Icons.payment_rounded,
            label: appointment.isDemoBooking
                ? 'Предоплата ${appointment.depositPercent}% (тест)'
                : 'appointments.pay'.tr(),
            onTap: () => _showPaymentMethods(context, appointment),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_calendar_outlined,
                  label: 'appointments.reschedule'.tr(),
                  onTap: () => _pickSlot(context, appointment, repeat: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.close_rounded,
                  label: 'appointments.cancel'.tr(),
                  outlined: true,
                  onTap: () => _confirmCancel(context, appointment),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.info_outline_rounded,
            label: 'appointments.details'.tr(),
            outlined: true,
            onTap: () => _showDetails(context, appointment),
          ),
        ],
      );
    }
    if (isUpcoming) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_calendar_outlined,
                  label: 'appointments.reschedule'.tr(),
                  onTap: () => _pickSlot(context, appointment, repeat: false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.close_rounded,
                  label: 'appointments.cancel'.tr(),
                  outlined: true,
                  onTap: () => _confirmCancel(context, appointment),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ActionButton(
            icon: Icons.info_outline_rounded,
            label: 'appointments.details'.tr(),
            outlined: true,
            onTap: () => _showDetails(context, appointment),
          ),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.refresh_rounded,
                label: 'appointments.repeat'.tr(),
                onTap: () => _pickSlot(context, appointment, repeat: true),
              ),
            ),
            if (appointment.status == AppointmentStatus.completed &&
                !appointment.reviewSubmitted) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.star_border_rounded,
                  label: 'appointments.leave_review'.tr(),
                  outlined: true,
                  onTap: () => _showReview(context, appointment),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _ActionButton(
          icon: Icons.info_outline_rounded,
          label: 'appointments.details'.tr(),
          outlined: true,
          onTap: () => _showDetails(context, appointment),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 43,
    child: outlined
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: _pink,
              side: const BorderSide(color: Color(0xFFFF83C5), width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          )
        : FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(
              minimumSize: Size.zero,
              foregroundColor: _pink,
              backgroundColor: const Color(0xFFFFE7F3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
  );
}

Future<void> _confirmCancel(
  BuildContext context,
  Appointment appointment,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('appointments.cancel_title'.tr()),
      content: Text('appointments.cancel_message'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('appointments.keep'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text('appointments.confirm_cancel'.tr()),
        ),
      ],
    ),
  );
  if (confirm == true && context.mounted) {
    context.read<AppointmentsBloc>().add(AppointmentCancelled(appointment.id));
  }
}

Future<void> _showPaymentMethods(
  BuildContext context,
  Appointment appointment,
) async {
  final method = await showModalBottomSheet<AppointmentPaymentMethod>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appointments.payment_method'.tr(),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            if (appointment.isDemoBooking) ...[
              const SizedBox(height: 8),
              Text(
                'Предоплата ${appointment.depositPercent}%: ${_moneyAmount(appointment.depositAmount)}. Остаток ${_moneyAmount(appointment.remainingAmount)} — после услуги. Это тест: деньги не списываются.',
                style: const TextStyle(color: Color(0xFF7D8797), height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            _PaymentOption(
              icon: Icons.account_balance_wallet_outlined,
              label: 'appointments.credits'.tr(),
              method: AppointmentPaymentMethod.credits,
            ),
            _PaymentOption(
              icon: Icons.credit_card_rounded,
              label: 'appointments.online'.tr(),
              method: AppointmentPaymentMethod.online,
            ),
            if (appointment.canPayAtSalon)
              _PaymentOption(
                icon: Icons.storefront_outlined,
                label: 'appointments.at_salon'.tr(),
                method: AppointmentPaymentMethod.atSalon,
              ),
          ],
        ),
      ),
    ),
  );
  if (method != null && context.mounted) {
    context.read<AppointmentsBloc>().add(
      AppointmentPaymentSubmitted(
        appointmentId: appointment.id,
        method: method,
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.label,
    required this.method,
  });
  final IconData icon;
  final String label;
  final AppointmentPaymentMethod method;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFE8F3),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: _pink),
    ),
    title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => Navigator.pop(context, method),
  );
}

Future<void> _pickSlot(
  BuildContext context,
  Appointment appointment, {
  required bool repeat,
}) async {
  final now = DateTime.now().toUtc();
  final slots = List.generate(4, (index) {
    final day = now.add(Duration(days: index + 1));
    return DateTime.utc(
      day.year,
      day.month,
      day.day,
      index.isEven ? 11 : 16,
      30,
    );
  });
  final slot = await showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appointments.select_time'.tr(),
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'appointments.available_slots'.tr(),
              style: const TextStyle(color: Color(0xFF7D8797), fontSize: 13),
            ),
            const SizedBox(height: 12),
            for (final currentSlot in slots)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_month_outlined,
                  color: _pink,
                ),
                title: Text(
                  _dateTimeLabel(currentSlot.add(appointment.salonUtcOffset)),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sheetContext, currentSlot),
              ),
          ],
        ),
      ),
    ),
  );
  if (slot == null || !context.mounted) return;
  final bloc = context.read<AppointmentsBloc>();
  bloc.add(
    repeat
        ? AppointmentRepeated(appointmentId: appointment.id, startsAtUtc: slot)
        : AppointmentRescheduled(
            appointmentId: appointment.id,
            startsAtUtc: slot,
          ),
  );
}

Future<void> _showReview(BuildContext context, Appointment appointment) async {
  var rating = 5;
  final submit = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('appointments.review_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'appointments.review_hint'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7D8797)),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () => setState(() => rating = index + 1),
                  icon: Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _pink,
                    size: 31,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('appointments.send_review'.tr()),
          ),
        ],
      ),
    ),
  );
  if (submit == true && context.mounted) {
    context.read<AppointmentsBloc>().add(
      AppointmentReviewSubmitted(appointment.id),
    );
  }
}

Future<void> _showDetails(BuildContext context, Appointment appointment) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.serviceName,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _DetailRow(Icons.storefront_outlined, appointment.salonName),
              _DetailRow(Icons.person_outline_rounded, appointment.masterName),
              _DetailRow(
                Icons.calendar_month_outlined,
                _dateTimeLabel(appointment.salonStartsAt),
              ),
              _DetailRow(
                Icons.schedule_rounded,
                '${appointment.durationMinutes} ${'appointments.minutes'.tr()}',
              ),
              _DetailRow(
                Icons.account_balance_wallet_outlined,
                _priceLabel(appointment),
              ),
            ],
          ),
        ),
      ),
    );

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.value);
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, color: _pink, size: 20),
        const SizedBox(width: 11),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _PinkGlow extends StatelessWidget {
  const _PinkGlow();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: 250,
      height: 250,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x26FF6EB6), Color(0x00FFF9FC)],
        ),
      ),
    ),
  );
}

String _dateLabel(DateTime value) {
  const months = [
    'янв',
    'фев',
    'мар',
    'апр',
    'мая',
    'июн',
    'июл',
    'авг',
    'сен',
    'окт',
    'ноя',
    'дек',
  ];
  return '${value.day} ${months[value.month - 1]}';
}

String _timeLabel(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _dateTimeLabel(DateTime value) =>
    '${_dateLabel(value)} · ${_timeLabel(value)}';

String _priceLabel(Appointment appointment) => appointment.priceIsCredits
    ? '${appointment.price} кр.'
    : _moneyAmount(appointment.price);

String _moneyAmount(int amount) =>
    '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} сум';
