part of 'auth_onboarding_bloc.dart';

enum AuthSubmissionStatus { initial, loading, success, failure }

class AuthOnboardingState extends Equatable {
  const AuthOnboardingState({
    this.step = 0,
    this.phone = '',
    this.otp = '',
    this.status = AuthSubmissionStatus.initial,
    this.errorMessage,
  });
  final int step;
  final String phone;
  final String otp;
  final AuthSubmissionStatus status;
  final String? errorMessage;

  AuthOnboardingState copyWith({
    int? step,
    String? phone,
    String? otp,
    AuthSubmissionStatus? status,
    String? errorMessage,
  }) => AuthOnboardingState(
    step: step ?? this.step,
    phone: phone ?? this.phone,
    otp: otp ?? this.otp,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [step, phone, otp, status, errorMessage];
}
