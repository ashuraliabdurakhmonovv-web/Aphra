import 'package:equatable/equatable.dart';

enum AppointmentStatus {
  confirmed,
  awaitingPayment,
  completed,
  cancelled,
  noShow,
}

enum AppointmentPaymentMethod { credits, online, atSalon }

class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.serviceName,
    required this.salonName,
    required this.masterName,
    required this.imageAsset,
    required this.startsAtUtc,
    required this.salonUtcOffset,
    required this.durationMinutes,
    required this.price,
    required this.priceIsCredits,
    required this.status,
    this.reviewSubmitted = false,
    this.canPayAtSalon = false,
    this.depositPercent = 0,
    this.isDemoBooking = false,
  });

  final String id;
  final String serviceName;
  final String salonName;
  final String masterName;
  final String imageAsset;
  final DateTime startsAtUtc;
  final Duration salonUtcOffset;
  final int durationMinutes;
  final int price;
  final bool priceIsCredits;
  final AppointmentStatus status;
  final bool reviewSubmitted;
  final bool canPayAtSalon;
  final int depositPercent;
  final bool isDemoBooking;

  int get depositAmount => price * depositPercent ~/ 100;
  int get remainingAmount => price - depositAmount;

  DateTime get salonStartsAt => startsAtUtc.toUtc().add(salonUtcOffset);

  bool get isUpcoming =>
      status == AppointmentStatus.confirmed ||
      status == AppointmentStatus.awaitingPayment;

  bool canManage(DateTime serverNowUtc) =>
      startsAtUtc.toUtc().difference(serverNowUtc.toUtc()) >
      const Duration(minutes: 30);

  bool isSoon(DateTime serverNowUtc) =>
      isUpcoming &&
      startsAtUtc.toUtc().difference(serverNowUtc.toUtc()) > Duration.zero &&
      !canManage(serverNowUtc);

  Appointment copyWith({
    DateTime? startsAtUtc,
    AppointmentStatus? status,
    bool? reviewSubmitted,
  }) => Appointment(
    id: id,
    serviceName: serviceName,
    salonName: salonName,
    masterName: masterName,
    imageAsset: imageAsset,
    startsAtUtc: startsAtUtc ?? this.startsAtUtc,
    salonUtcOffset: salonUtcOffset,
    durationMinutes: durationMinutes,
    price: price,
    priceIsCredits: priceIsCredits,
    status: status ?? this.status,
    reviewSubmitted: reviewSubmitted ?? this.reviewSubmitted,
    canPayAtSalon: canPayAtSalon,
    depositPercent: depositPercent,
    isDemoBooking: isDemoBooking,
  );

  @override
  List<Object?> get props => [
    id,
    serviceName,
    salonName,
    masterName,
    imageAsset,
    startsAtUtc,
    salonUtcOffset,
    durationMinutes,
    price,
    priceIsCredits,
    status,
    reviewSubmitted,
    canPayAtSalon,
    depositPercent,
    isDemoBooking,
  ];
}
