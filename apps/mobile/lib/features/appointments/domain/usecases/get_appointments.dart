import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class GetAppointments implements UseCase<List<Appointment>, NoParams> {
  const GetAppointments(this._repository);
  final AppointmentRepository _repository;

  @override
  Future<Either<Failure, List<Appointment>>> call(NoParams params) =>
      _repository.getAppointments();
}
