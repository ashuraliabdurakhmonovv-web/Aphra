import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/registration_profile.dart';
import '../../../auth/domain/usecases/get_local_profile.dart';
import '../../../auth/domain/usecases/save_registration_profile.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._getLocalProfile, this._saveRegistrationProfile)
    : super(const ProfileState()) {
    on<ProfileStarted>(_onStarted);
    on<ProfileUpdated>(_onUpdated);
  }

  final GetLocalProfile _getLocalProfile;
  final SaveRegistrationProfile _saveRegistrationProfile;

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final result = await _getLocalProfile(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(status: ProfileStatus.failure, message: failure.message),
      ),
      (profile) =>
          emit(state.copyWith(status: ProfileStatus.ready, profile: profile)),
    );
  }

  Future<void> _onUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.saving));
    final result = await _saveRegistrationProfile(
      SaveRegistrationProfileParams(event.profile),
    );
    result.fold(
      (failure) => emit(
        state.copyWith(status: ProfileStatus.failure, message: failure.message),
      ),
      (_) => emit(
        state.copyWith(status: ProfileStatus.saved, profile: event.profile),
      ),
    );
  }
}
