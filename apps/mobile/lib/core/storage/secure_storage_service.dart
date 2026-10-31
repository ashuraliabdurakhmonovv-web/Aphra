import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStorageService {
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> clearAccessToken();
}

final class SecureStorageServiceImpl implements SecureStorageService {
  const SecureStorageServiceImpl(this._storage);
  static const _accessTokenKey = 'access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);
  @override
  Future<void> clearAccessToken() => _storage.delete(key: _accessTokenKey);
}
