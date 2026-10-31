import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_mock_data_source.dart';

final class AppointmentRepositoryImpl implements AppointmentRepository {
  const AppointmentRepositoryImpl(this._source);
  final AppointmentMockDataSource _source;

  @override
  Future<Either<Failure, List<Appointment>>> getAppointments() =>
      _guard(_source.getAppointments);

  @override
  Future<Either<Failure, Appointment>> createDemoBooking(
    Appointment appointment,
  ) => _guard(() => _source.createDemoBooking(appointment));

  @override
  Future<Either<Failure, Appointment>> cancel(String appointmentId) =>
      _guard(() => _source.cancel(appointmentId));

  @override
  Future<Either<Failure, Appointment>> reschedule({
    required String appointmentId,
    required DateTime startsAtUtc,
  }) => _guard(
    () => _source.reschedule(
      appointmentId: appointmentId,
      startsAtUtc: startsAtUtc,
    ),
  );

  @override
  Future<Either<Failure, Appointment>> pay({
    required String appointmentId,
    required AppointmentPaymentMethod method,
  }) => _guard(() => _source.pay(appointmentId: appointmentId, method: method));

  @override
  Future<Either<Failure, Appointment>> submitReview(String appointmentId) =>
      _guard(() => _source.submitReview(appointmentId));

  @override
  Future<Either<Failure, Appointment>> repeat({
    required String appointmentId,
    required DateTime startsAtUtc,
  }) => _guard(
    () =>
        _source.repeat(appointmentId: appointmentId, startsAtUtc: startsAtUtc),
  );

  Future<Either<Failure, Result>> _guard<Result>(
    Future<Result> Function() request,
  ) async {
    try {
      return Right(await request());
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } on AppException catch (error) {
      return Left(UnexpectedFailure(error.message));
    } on Object {
      return const Left(UnexpectedFailure('Unexpected error'));
    }
  }
}
