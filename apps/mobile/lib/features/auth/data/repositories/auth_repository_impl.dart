import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/registration_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

final class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._localDataSource);

  final AuthLocalDataSource _localDataSource;

  @override
  bool get hasLocalProfile => _localDataSource.hasProfile;

  @override
  Future<Either<Failure, RegistrationProfile?>> getProfile() async {
    try {
      return Right(_localDataSource.getProfile());
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } on Object {
      return const Left(UnexpectedFailure('Could not read local profile'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveProfile(RegistrationProfile profile) async {
    try {
      await _localDataSource.saveProfile(profile);
      return const Right(unit);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } on Object {
      return const Left(UnexpectedFailure('Could not save local profile'));
    }
  }
}
