import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesService {
  String? get localeCode;
  Future<void> saveLocaleCode(String code);
}

final class PreferencesServiceImpl implements PreferencesService {
  const PreferencesServiceImpl(this._preferences);
  static const _localeKey = 'locale_code';
  final SharedPreferences _preferences;

  @override
  String? get localeCode => _preferences.getString(_localeKey);
  @override
  Future<void> saveLocaleCode(String code) =>
      _preferences.setString(_localeKey, code);
}
