import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/place.dart';
import '../../domain/usecases/get_places.dart';

part 'explore_bloc.freezed.dart';
part 'explore_event.dart';
part 'explore_state.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc(this._getPlaces) : super(const ExploreState.initial()) {
    on<_Started>(_onStarted);
    on<_Refreshed>(_onStarted);
  }
  final GetPlaces _getPlaces;
  Future<void> _onStarted(
    ExploreEvent event,
    Emitter<ExploreState> emit,
  ) async {
    emit(const ExploreState.loading());
    final result = await _getPlaces(const NoParams());
    result.fold(
      (failure) => emit(ExploreState.failure(failure.message)),
      (places) => emit(ExploreState.success(places)),
    );
  }
}
