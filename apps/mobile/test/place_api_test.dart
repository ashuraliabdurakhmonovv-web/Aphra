import 'package:cosmetic_map/core/network/dio_client.dart';
import 'package:cosmetic_map/features/explore/data/datasources/place_remote_data_source.dart';
import 'package:cosmetic_map/features/explore/data/datasources/place_preview_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final baseUrl in [
    'http://127.0.0.1:8000/api/v1',
    'http://127.0.0.1:8000/api/v1/',
  ]) {
    test('requests places correctly with base URL "$baseUrl"', () async {
      final dio = Dio(BaseOptions(baseUrl: normalizeApiBaseUrl(baseUrl)));
      Uri? requestedUri;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestedUri = options.uri;
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                data: {'results': <dynamic>[]},
              ),
            );
          },
        ),
      );

      final places = await PlaceRemoteDataSourceImpl(dio).getPlaces();

      expect(places, isEmpty);
      expect(requestedUri.toString(), 'http://127.0.0.1:8000/api/v1/places/');
    });
  }

  test('debug preview includes fifteen valid salon locations', () {
    expect(PlacePreviewData.models, hasLength(15));
    for (final place in PlacePreviewData.models) {
      expect(place.latitude, inInclusiveRange(-90, 90));
      expect(place.longitude, inInclusiveRange(-180, 180));
    }
  });
}
