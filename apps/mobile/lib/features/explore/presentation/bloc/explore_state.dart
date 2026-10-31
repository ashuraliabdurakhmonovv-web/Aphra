part of 'explore_bloc.dart';

@freezed
sealed class ExploreState with _$ExploreState {
  const factory ExploreState.initial() = _Initial;
  const factory ExploreState.loading() = _Loading;
  const factory ExploreState.success(List<Place> places) = _Success;
  const factory ExploreState.failure(String message) = _Failure;
}
