import '../../../../core/error/exceptions.dart';
import '../../domain/entities/appointment.dart';

/// Development-only adapter used until the booking API is available.
/// All mutations live only for the current application session.
abstract interface class AppointmentMockDataSource {
  Future<List<Appointment>> getAppointments();
  Future<Appointment> createDemoBooking(Appointment appointment);
  Future<Appointment> cancel(String appointmentId);
  Future<Appointment> reschedule({
    required String appointmentId,
    required DateTime startsAtUtc,
  });
  Future<Appointment> pay({
    required String appointmentId,
    required AppointmentPaymentMethod method,
  });
  Future<Appointment> submitReview(String appointmentId);
  Future<Appointment> repeat({
    required String appointmentId,
    required DateTime startsAtUtc,
  });
}

final class AppointmentMockDataSourceImpl implements AppointmentMockDataSource {
  AppointmentMockDataSourceImpl()
    : _appointments = _seed(DateTime.now().toUtc());

  final List<Appointment> _appointments;

  @override
  Future<List<Appointment>> getAppointments() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_appointments);
  }

  @override
  Future<Appointment> createDemoBooking(Appointment appointment) async {
    if (!appointment.isDemoBooking ||
        appointment.startsAtUtc.toUtc().isBefore(_serverNowUtc)) {
      throw const ServerException('Это время больше недоступно');
    }
    final taken = _appointments.any(
      (item) =>
          item.isUpcoming &&
          item.salonName == appointment.salonName &&
          item.masterName == appointment.masterName &&
          item.startsAtUtc == appointment.startsAtUtc,
    );
    if (taken) throw const ServerException('Это время уже занято');
    _appointments.add(appointment);
    return appointment;
  }

  @override
  Future<Appointment> cancel(String appointmentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _indexOf(appointmentId);
    final current = _appointments[index];
    if (!current.canManage(_serverNowUtc)) {
      throw const ServerException('Cancellation is no longer available');
    }
    return _replace(
      index,
      current.copyWith(status: AppointmentStatus.cancelled),
    );
  }

  @override
  Future<Appointment> reschedule({
    required String appointmentId,
    required DateTime startsAtUtc,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _indexOf(appointmentId);
    final current = _appointments[index];
    if (!current.canManage(_serverNowUtc) ||
        startsAtUtc.toUtc().isBefore(
          _serverNowUtc.add(const Duration(hours: 1)),
        )) {
      throw const ServerException('Selected slot is unavailable');
    }
    return _replace(index, current.copyWith(startsAtUtc: startsAtUtc.toUtc()));
  }

  @override
  Future<Appointment> pay({
    required String appointmentId,
    required AppointmentPaymentMethod method,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _indexOf(appointmentId);
    final current = _appointments[index];
    if (current.status != AppointmentStatus.awaitingPayment) {
      throw const ServerException('Payment is not required');
    }
    return _replace(
      index,
      current.copyWith(status: AppointmentStatus.confirmed),
    );
  }

  @override
  Future<Appointment> submitReview(String appointmentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final index = _indexOf(appointmentId);
    final current = _appointments[index];
    if (current.status != AppointmentStatus.completed) {
      throw const ServerException(
        'Review is available after a completed visit',
      );
    }
    return _replace(index, current.copyWith(reviewSubmitted: true));
  }

  @override
  Future<Appointment> repeat({
    required String appointmentId,
    required DateTime startsAtUtc,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final source = _appointments[_indexOf(appointmentId)];
    if (startsAtUtc.toUtc().isBefore(
      _serverNowUtc.add(const Duration(hours: 1)),
    )) {
      throw const ServerException('Selected slot is unavailable');
    }
    final repeated = Appointment(
      id: 'repeat-${DateTime.now().microsecondsSinceEpoch}',
      serviceName: source.serviceName,
      salonName: source.salonName,
      masterName: source.masterName,
      imageAsset: source.imageAsset,
      startsAtUtc: startsAtUtc.toUtc(),
      salonUtcOffset: source.salonUtcOffset,
      durationMinutes: source.durationMinutes,
      price: source.price,
      priceIsCredits: source.priceIsCredits,
      status: AppointmentStatus.confirmed,
      canPayAtSalon: source.canPayAtSalon,
      depositPercent: source.depositPercent,
      isDemoBooking: source.isDemoBooking,
    );
    _appointments.add(repeated);
    return repeated;
  }

  DateTime get _serverNowUtc => DateTime.now().toUtc();

  int _indexOf(String id) {
    final index = _appointments.indexWhere(
      (appointment) => appointment.id == id,
    );
    if (index == -1) throw const ServerException('Appointment was not found');
    return index;
  }

  Appointment _replace(int index, Appointment appointment) {
    _appointments[index] = appointment;
    return appointment;
  }

  static List<Appointment> _seed(DateTime serverNowUtc) {
    DateTime after({
      required int days,
      required int hour,
      required int minute,
    }) {
      final local = serverNowUtc.add(const Duration(hours: 5));
      final date = DateTime.utc(
        local.year,
        local.month,
        local.day,
        hour,
        minute,
      );
      return date.subtract(const Duration(hours: 5)).add(Duration(days: days));
    }

    return [
      Appointment(
        id: 'upcoming-confirmed',
        serviceName: 'Маникюр классический',
        salonName: 'Nur Beauty',
        masterName: 'Сабина',
        imageAsset: 'assets/images/profile/manicure.png',
        startsAtUtc: after(days: 2, hour: 15, minute: 30),
        salonUtcOffset: const Duration(hours: 5),
        durationMinutes: 60,
        price: 34,
        priceIsCredits: true,
        status: AppointmentStatus.confirmed,
      ),
      Appointment(
        id: 'upcoming-payment',
        serviceName: 'Окрашивание бровей',
        salonName: 'Lola Studio',
        masterName: 'Алена',
        imageAsset: 'assets/images/profile/brows.png',
        startsAtUtc: after(days: 1, hour: 11, minute: 0),
        salonUtcOffset: const Duration(hours: 5),
        durationMinutes: 40,
        price: 120000,
        priceIsCredits: false,
        status: AppointmentStatus.awaitingPayment,
        canPayAtSalon: true,
      ),
      Appointment(
        id: 'upcoming-soon',
        serviceName: 'Укладка и уход',
        salonName: 'Mira Hair',
        masterName: 'Дилноза',
        imageAsset: 'assets/images/profile/haircut.png',
        startsAtUtc: serverNowUtc.add(const Duration(minutes: 22)),
        salonUtcOffset: const Duration(hours: 5),
        durationMinutes: 60,
        price: 40,
        priceIsCredits: true,
        status: AppointmentStatus.confirmed,
      ),
      Appointment(
        id: 'history-completed',
        serviceName: 'Укладка и уход',
        salonName: 'Mira Hair',
        masterName: 'Дилноза',
        imageAsset: 'assets/images/profile/haircut.png',
        startsAtUtc: after(days: -2, hour: 15, minute: 30),
        salonUtcOffset: const Duration(hours: 5),
        durationMinutes: 60,
        price: 40,
        priceIsCredits: true,
        status: AppointmentStatus.completed,
      ),
      Appointment(
        id: 'history-reviewed',
        serviceName: 'Коррекция бровей',
        salonName: 'Nur Beauty',
        masterName: 'Алена',
        imageAsset: 'assets/images/profile/brows.png',
        startsAtUtc: after(days: -9, hour: 14, minute: 0),
        salonUtcOffset: const Duration(hours: 5),
        durationMinutes: 40,
        price: 30,
        priceIsCredits: true,
        status: AppointmentStatus.completed,
        reviewSubmitted: true,
      ),
      Appointment(
        id: 'history-cancelled',
        serviceName: 'Стрижка женская',
        salonName: 'Mira Hair',
        masterName: 'Мадина',
        imageAsset: 'assets/images/profile/avatar.png',
        startsAtUtc: after(days: -18, hour: 11, minute: 0),
        salonUtcOffset: const Duration(hours: 5),
        durationMinutes: 45,
        price: 150000,
        priceIsCredits: false,
        status: AppointmentStatus.cancelled,
      ),
      Appointment(
        id: 'history-no-show',
        serviceName: 'Ламинирование ресниц',
        salonName: 'Lola Studio',
        masterName: 'Алина',
        imageAsset: 'assets/images/profile/brows.png',
        startsAtUtc: after(days: -25, hour: 10, minute: 30),
        salonUtcOffset: const Duration(hours: 5),
        durationMinutes: 50,
        price: 45,
        priceIsCredits: true,
        status: AppointmentStatus.noShow,
      ),
    ];
  }
}
