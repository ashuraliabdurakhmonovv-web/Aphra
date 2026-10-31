import 'package:hive_ce/hive.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/entities/registration_profile.dart';

abstract interface class AuthLocalDataSource {
  bool get hasProfile;
  RegistrationProfile? getProfile();
  Future<void> saveProfile(RegistrationProfile profile);
}

final class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._box);

  static const _profileKey = 'registration_profile';
  final Box<dynamic> _box;

  @override
  bool get hasProfile => _box.containsKey(_profileKey);

  @override
  RegistrationProfile? getProfile() {
    try {
      final value = _box.get(_profileKey);
      if (value is! Map) return null;
      return RegistrationProfile(
        phone: value['phone'] as String,
        firstName: value['first_name'] as String,
        lastName: value['last_name'] as String,
        birthDate: DateTime.parse(value['birth_date'] as String),
        gender: UserGender.values.byName(value['gender'] as String),
      );
    } on Object {
      throw const CacheException();
    }
  }

  @override
  Future<void> saveProfile(RegistrationProfile profile) async {
    try {
      await _box.put(_profileKey, <String, Object>{
        'phone': profile.phone,
        'first_name': profile.firstName,
        'last_name': profile.lastName,
        'birth_date': profile.birthDate.toIso8601String(),
        'gender': profile.gender.name,
      });
    } on Object {
      throw const CacheException();
    }
  }
}
