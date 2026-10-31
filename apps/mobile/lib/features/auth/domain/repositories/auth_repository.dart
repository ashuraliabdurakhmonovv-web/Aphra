import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/registration_profile.dart';

abstract interface class AuthRepository {
  bool get hasLocalProfile;
  Future<Either<Failure, RegistrationProfile?>> getProfile();
  Future<Either<Failure, Unit>> saveProfile(RegistrationProfile profile);
}
