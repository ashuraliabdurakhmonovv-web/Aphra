part of 'appointments_bloc.dart';

enum AppointmentsStatus { initial, loading, ready, working, failure }

enum AppointmentsTab { upcoming, history }

class AppointmentsState extends Equatable {
  const AppointmentsState({
    this.status = AppointmentsStatus.initial,
    this.selectedTab = AppointmentsTab.upcoming,
    this.appointments = const [],
    this.serverNowUtc,
    this.message,
  });

  final AppointmentsStatus status;
  final AppointmentsTab selectedTab;
  final List<Appointment> appointments;
  final DateTime? serverNowUtc;
  final String? message;

  List<Appointment> get upcoming =>
      appointments.where((appointment) => appointment.isUpcoming).toList()
        ..sort((a, b) => a.startsAtUtc.compareTo(b.startsAtUtc));

  List<Appointment> get history =>
      appointments.where((appointment) => !appointment.isUpcoming).toList()
        ..sort((a, b) => b.startsAtUtc.compareTo(a.startsAtUtc));

  AppointmentsState copyWith({
    AppointmentsStatus? status,
    AppointmentsTab? selectedTab,
    List<Appointment>? appointments,
    DateTime? serverNowUtc,
    String? message,
    bool clearMessage = false,
  }) => AppointmentsState(
    status: status ?? this.status,
    selectedTab: selectedTab ?? this.selectedTab,
    appointments: appointments ?? this.appointments,
    serverNowUtc: serverNowUtc ?? this.serverNowUtc,
    message: clearMessage ? null : message ?? this.message,
  );

  @override
  List<Object?> get props => [
    status,
    selectedTab,
    appointments,
    serverNowUtc,
    message,
  ];
}
