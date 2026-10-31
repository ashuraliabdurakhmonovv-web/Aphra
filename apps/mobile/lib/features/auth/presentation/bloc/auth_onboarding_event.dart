part of 'auth_onboarding_bloc.dart';

sealed class AuthOnboardingEvent extends Equatable {
  const AuthOnboardingEvent();
  @override
  List<Object?> get props => [];
}

final class AuthNextPressed extends AuthOnboardingEvent {
  const AuthNextPressed();
}

final class AuthBackPressed extends AuthOnboardingEvent {
  const AuthBackPressed();
}

final class AuthPhoneChanged extends AuthOnboardingEvent {
  const AuthPhoneChanged(this.phone);
  final String phone;
  @override
  List<Object?> get props => [phone];
}

final class AuthOtpChanged extends AuthOnboardingEvent {
  const AuthOtpChanged(this.otp);
  final String otp;
  @override
  List<Object?> get props => [otp];
}

final class AuthRegistrationSubmitted extends AuthOnboardingEvent {
  const AuthRegistrationSubmitted(this.profile);

  final RegistrationProfile profile;

  @override
  List<Object?> get props => [profile];
}
