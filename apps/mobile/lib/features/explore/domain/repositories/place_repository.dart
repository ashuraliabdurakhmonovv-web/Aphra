import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/place.dart';

abstract interface class PlaceRepository {
  Future<Either<Failure, List<Place>>> getPlaces();
}
