part of 'explore_bloc.dart';

@freezed
sealed class ExploreEvent with _$ExploreEvent {
  const factory ExploreEvent.started() = _Started;
  const factory ExploreEvent.refreshed() = _Refreshed;
}
