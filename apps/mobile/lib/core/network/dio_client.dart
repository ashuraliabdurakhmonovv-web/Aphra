import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';

String normalizeApiBaseUrl(String baseUrl) {
  final withoutTrailingSlashes = baseUrl.trim().replaceFirst(
    RegExp(r'/+$'),
    '',
  );
  return '$withoutTrailingSlashes/';
}

class DioClient {
  DioClient({required SecureStorageService secureStorage})
    : dio = Dio(
        BaseOptions(
          baseUrl: normalizeApiBaseUrl(
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://localhost:8000/api/v1',
            ),
          ),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.readAccessToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
}
