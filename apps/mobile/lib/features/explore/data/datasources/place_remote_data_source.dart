import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/place_model.dart';

abstract interface class PlaceRemoteDataSource {
  Future<List<PlaceModel>> getPlaces();
}

final class PlaceRemoteDataSourceImpl implements PlaceRemoteDataSource {
  const PlaceRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<List<PlaceModel>> getPlaces() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('places/');
      final results = response.data?['results'];
      if (results is! List) {
        throw const ParsingException();
      }
      return results
          .map((item) => PlaceModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const UnauthorizedException();
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException();
      }
      throw ServerException(
        error.message ?? 'Server request failed',
        statusCode: error.response?.statusCode,
      );
    } on AppException {
      rethrow;
    } on Object {
      throw const ParsingException();
    }
  }
}
