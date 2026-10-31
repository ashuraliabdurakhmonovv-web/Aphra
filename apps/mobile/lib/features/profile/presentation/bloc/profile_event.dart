part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

final class ProfileStarted extends ProfileEvent {
  const ProfileStarted();
}

final class ProfileUpdated extends ProfileEvent {
  const ProfileUpdated(this.profile);

  final RegistrationProfile profile;

  @override
  List<Object?> get props => [profile];
}
