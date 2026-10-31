part of 'appointments_bloc.dart';

sealed class AppointmentsEvent extends Equatable {
  const AppointmentsEvent();

  @override
  List<Object?> get props => [];
}

final class AppointmentsStarted extends AppointmentsEvent {
  const AppointmentsStarted();
}

final class AppointmentsTabSelected extends AppointmentsEvent {
  const AppointmentsTabSelected(this.tab);
  final AppointmentsTab tab;

  @override
  List<Object?> get props => [tab];
}

final class AppointmentCancelled extends AppointmentsEvent {
  const AppointmentCancelled(this.appointmentId);
  final String appointmentId;

  @override
  List<Object?> get props => [appointmentId];
}

final class AppointmentRescheduled extends AppointmentsEvent {
  const AppointmentRescheduled({
    required this.appointmentId,
    required this.startsAtUtc,
  });
  final String appointmentId;
  final DateTime startsAtUtc;

  @override
  List<Object?> get props => [appointmentId, startsAtUtc];
}

final class AppointmentPaymentSubmitted extends AppointmentsEvent {
  const AppointmentPaymentSubmitted({
    required this.appointmentId,
    required this.method,
  });
  final String appointmentId;
  final AppointmentPaymentMethod method;

  @override
  List<Object?> get props => [appointmentId, method];
}

final class AppointmentReviewSubmitted extends AppointmentsEvent {
  const AppointmentReviewSubmitted(this.appointmentId);
  final String appointmentId;

  @override
  List<Object?> get props => [appointmentId];
}

final class AppointmentRepeated extends AppointmentsEvent {
  const AppointmentRepeated({
    required this.appointmentId,
    required this.startsAtUtc,
  });
  final String appointmentId;
  final DateTime startsAtUtc;

  @override
  List<Object?> get props => [appointmentId, startsAtUtc];
}
