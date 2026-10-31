import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/registration_profile.dart';
import '../repositories/auth_repository.dart';

class SaveRegistrationProfile
    implements UseCase<Unit, SaveRegistrationProfileParams> {
  const SaveRegistrationProfile(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SaveRegistrationProfileParams params) =>
      _repository.saveProfile(params.profile);
}

class SaveRegistrationProfileParams extends Equatable {
  const SaveRegistrationProfileParams(this.profile);

  final RegistrationProfile profile;

  @override
  List<Object> get props => [profile];
}
