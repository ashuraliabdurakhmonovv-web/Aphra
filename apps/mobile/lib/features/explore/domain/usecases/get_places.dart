import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/place.dart';
import '../repositories/place_repository.dart';

final class GetPlaces implements UseCase<List<Place>, NoParams> {
  const GetPlaces(this._repository);
  final PlaceRepository _repository;
  @override
  Future<Either<Failure, List<Place>>> call(NoParams params) =>
      _repository.getPlaces();
}
