import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../datasources/place_local_data_source.dart';
import '../datasources/place_preview_data.dart';
import '../datasources/place_remote_data_source.dart';

final class PlaceRepositoryImpl implements PlaceRepository {
  const PlaceRepositoryImpl({required this.remote, required this.local});
  final PlaceRemoteDataSource remote;
  final PlaceLocalDataSource local;

  @override
  Future<Either<Failure, List<Place>>> getPlaces() async {
    try {
      final models = await remote.getPlaces();
      final visibleModels = models.isEmpty && kDebugMode
          ? PlacePreviewData.models
          : models;
      await local.cachePlaces(visibleModels);
      return Right(visibleModels.map((model) => model.toEntity()).toList());
    } on NetworkException catch (error) {
      final cached = local.getCachedPlaces();
      if (cached.isNotEmpty) {
        return Right(cached.map((model) => model.toEntity()).toList());
      }
      if (kDebugMode) return Right(_previewPlaces());
      return Left(NetworkFailure(error.message));
    } on UnauthorizedException catch (error) {
      return Left(UnauthorizedFailure(error.message));
    } on ServerException catch (error) {
      return Left(ServerFailure(error.message));
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } on AppException catch (error) {
      return Left(UnexpectedFailure(error.message));
    } on Object {
      return const Left(UnexpectedFailure('Unexpected error'));
    }
  }

  List<Place> _previewPlaces() => PlacePreviewData.models
      .map((model) => model.toEntity())
      .toList(growable: false);
}
