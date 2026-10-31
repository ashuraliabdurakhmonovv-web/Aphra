import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../../domain/usecases/get_appointments.dart';

part 'appointments_event.dart';
part 'appointments_state.dart';

class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  AppointmentsBloc(this._getAppointments, this._repository)
    : super(const AppointmentsState()) {
    on<AppointmentsStarted>(_onStarted);
    on<AppointmentsTabSelected>(_onTabSelected);
    on<AppointmentCancelled>(_onCancelled);
    on<AppointmentRescheduled>(_onRescheduled);
    on<AppointmentPaymentSubmitted>(_onPaymentSubmitted);
    on<AppointmentReviewSubmitted>(_onReviewSubmitted);
    on<AppointmentRepeated>(_onRepeated);
  }

  final GetAppointments _getAppointments;
  final AppointmentRepository _repository;

  Future<void> _onStarted(
    AppointmentsStarted event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(state.copyWith(status: AppointmentsStatus.loading));
    final result = await _getAppointments(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AppointmentsStatus.failure,
          message: failure.message,
        ),
      ),
      (appointments) => emit(
        state.copyWith(
          status: AppointmentsStatus.ready,
          appointments: _sort(appointments),
          serverNowUtc: DateTime.now().toUtc(),
          clearMessage: true,
        ),
      ),
    );
  }

  void _onTabSelected(
    AppointmentsTabSelected event,
    Emitter<AppointmentsState> emit,
  ) => emit(state.copyWith(selectedTab: event.tab));

  Future<void> _onCancelled(
    AppointmentCancelled event,
    Emitter<AppointmentsState> emit,
  ) async {
    await _perform(
      emit,
      () => _repository.cancel(event.appointmentId),
      successMessage: 'appointments.cancelled_success',
      selectedTab: AppointmentsTab.history,
    );
  }

  Future<void> _onRescheduled(
    AppointmentRescheduled event,
    Emitter<AppointmentsState> emit,
  ) async {
    await _perform(
      emit,
      () => _repository.reschedule(
        appointmentId: event.appointmentId,
        startsAtUtc: event.startsAtUtc,
      ),
      successMessage: 'appointments.rescheduled_success',
    );
  }

  Future<void> _onPaymentSubmitted(
    AppointmentPaymentSubmitted event,
    Emitter<AppointmentsState> emit,
  ) async {
    await _perform(
      emit,
      () => _repository.pay(
        appointmentId: event.appointmentId,
        method: event.method,
      ),
      successMessage: 'appointments.payment_success',
    );
  }

  Future<void> _onReviewSubmitted(
    AppointmentReviewSubmitted event,
    Emitter<AppointmentsState> emit,
  ) async {
    await _perform(
      emit,
      () => _repository.submitReview(event.appointmentId),
      successMessage: 'appointments.review_success',
    );
  }

  Future<void> _onRepeated(
    AppointmentRepeated event,
    Emitter<AppointmentsState> emit,
  ) async {
    await _perform(
      emit,
      () => _repository.repeat(
        appointmentId: event.appointmentId,
        startsAtUtc: event.startsAtUtc,
      ),
      successMessage: 'appointments.repeat_success',
      selectedTab: AppointmentsTab.upcoming,
      appendResult: true,
    );
  }

  Future<void> _perform(
    Emitter<AppointmentsState> emit,
    Future<dynamic> Function() action, {
    required String successMessage,
    AppointmentsTab? selectedTab,
    bool appendResult = false,
  }) async {
    emit(
      state.copyWith(status: AppointmentsStatus.working, clearMessage: true),
    );
    final result = await action();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AppointmentsStatus.failure,
          message: failure.message,
        ),
      ),
      (appointment) {
        final existing = List<Appointment>.from(state.appointments);
        final index = existing.indexWhere((item) => item.id == appointment.id);
        if (index >= 0 && !appendResult) {
          existing[index] = appointment;
        } else {
          existing.add(appointment);
        }
        emit(
          state.copyWith(
            status: AppointmentsStatus.ready,
            appointments: _sort(existing),
            selectedTab: selectedTab ?? state.selectedTab,
            serverNowUtc: DateTime.now().toUtc(),
            message: successMessage,
          ),
        );
      },
    );
  }

  static List<Appointment> _sort(List<Appointment> items) {
    final sorted = List<Appointment>.from(items);
    sorted.sort((a, b) => b.startsAtUtc.compareTo(a.startsAtUtc));
    return sorted;
  }
}
