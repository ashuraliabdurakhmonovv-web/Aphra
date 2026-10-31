import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/registration_profile.dart';
import '../repositories/auth_repository.dart';

class GetLocalProfile implements UseCase<RegistrationProfile?, NoParams> {
  const GetLocalProfile(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, RegistrationProfile?>> call(NoParams params) =>
      _repository.getProfile();
}
