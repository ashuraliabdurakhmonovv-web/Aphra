import 'package:cosmetic_map/core/error/failures.dart';
import 'package:cosmetic_map/features/auth/domain/entities/registration_profile.dart';
import 'package:cosmetic_map/features/auth/domain/repositories/auth_repository.dart';
import 'package:cosmetic_map/features/auth/domain/usecases/save_registration_profile.dart';
import 'package:cosmetic_map/features/auth/presentation/bloc/auth_onboarding_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('moves forward and backward within valid step range', () async {
    final bloc = AuthOnboardingBloc()..add(const AuthNextPressed());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.step, 1);

    bloc
      ..add(const AuthBackPressed())
      ..add(const AuthBackPressed());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.step, 0);

    await bloc.close();
  });

  test('stores phone and otp values', () async {
    final bloc = AuthOnboardingBloc()
      ..add(const AuthPhoneChanged('901234567'))
      ..add(const AuthOtpChanged('471200'));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.phone, '901234567');
    expect(bloc.state.otp, '471200');

    await bloc.close();
  });

  test('saves completed registration profile', () async {
    final repository = _FakeAuthRepository();
    final bloc = AuthOnboardingBloc(SaveRegistrationProfile(repository));
    final profile = RegistrationProfile(
      phone: '+998901234567',
      firstName: 'Nigina',
      lastName: 'Abdullaeva',
      birthDate: DateTime(1998, 3, 15),
      gender: UserGender.female,
    );

    bloc.add(AuthRegistrationSubmitted(profile));
    await bloc.stream.firstWhere(
      (state) => state.status == AuthSubmissionStatus.success,
    );

    expect(repository.savedProfile, profile);
    expect(bloc.state.status, AuthSubmissionStatus.success);
    await bloc.close();
  });
}

class _FakeAuthRepository implements AuthRepository {
  RegistrationProfile? savedProfile;

  @override
  bool get hasLocalProfile => savedProfile != null;

  @override
  Future<Either<Failure, RegistrationProfile?>> getProfile() async =>
      Right(savedProfile);

  @override
  Future<Either<Failure, Unit>> saveProfile(RegistrationProfile profile) async {
    savedProfile = profile;
    return const Right(unit);
  }
}
