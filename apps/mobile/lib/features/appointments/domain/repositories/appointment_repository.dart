import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/appointment.dart';

abstract interface class AppointmentRepository {
  Future<Either<Failure, List<Appointment>>> getAppointments();
  Future<Either<Failure, Appointment>> createDemoBooking(
    Appointment appointment,
  );
  Future<Either<Failure, Appointment>> cancel(String appointmentId);
  Future<Either<Failure, Appointment>> reschedule({
    required String appointmentId,
    required DateTime startsAtUtc,
  });
  Future<Either<Failure, Appointment>> pay({
    required String appointmentId,
    required AppointmentPaymentMethod method,
  });
  Future<Either<Failure, Appointment>> submitReview(String appointmentId);
  Future<Either<Failure, Appointment>> repeat({
    required String appointmentId,
    required DateTime startsAtUtc,
  });
}
