import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/registration_profile.dart';
import '../../domain/usecases/save_registration_profile.dart';

part 'auth_onboarding_event.dart';
part 'auth_onboarding_state.dart';

class AuthOnboardingBloc
    extends Bloc<AuthOnboardingEvent, AuthOnboardingState> {
  AuthOnboardingBloc([this._saveRegistrationProfile])
    : super(const AuthOnboardingState()) {
    on<AuthNextPressed>((event, emit) {
      if (state.step < 2) emit(state.copyWith(step: state.step + 1));
    });
    on<AuthBackPressed>((event, emit) {
      if (state.step > 0) emit(state.copyWith(step: state.step - 1));
    });
    on<AuthPhoneChanged>(
      (event, emit) => emit(state.copyWith(phone: event.phone)),
    );
    on<AuthOtpChanged>((event, emit) => emit(state.copyWith(otp: event.otp)));
    on<AuthRegistrationSubmitted>(_onRegistrationSubmitted);
  }

  final SaveRegistrationProfile? _saveRegistrationProfile;

  Future<void> _onRegistrationSubmitted(
    AuthRegistrationSubmitted event,
    Emitter<AuthOnboardingState> emit,
  ) async {
    final saveRegistrationProfile = _saveRegistrationProfile;
    if (saveRegistrationProfile == null) return;

    emit(state.copyWith(status: AuthSubmissionStatus.loading));
    final result = await saveRegistrationProfile(
      SaveRegistrationProfileParams(event.profile),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthSubmissionStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: AuthSubmissionStatus.success)),
    );
  }
}
