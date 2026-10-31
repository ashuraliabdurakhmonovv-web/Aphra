part of 'profile_bloc.dart';

enum ProfileStatus { initial, loading, ready, saving, saved, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.message,
  });

  final ProfileStatus status;
  final RegistrationProfile? profile;
  final String? message;

  ProfileState copyWith({
    ProfileStatus? status,
    RegistrationProfile? profile,
    String? message,
  }) => ProfileState(
    status: status ?? this.status,
    profile: profile ?? this.profile,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [status, profile, message];
}
