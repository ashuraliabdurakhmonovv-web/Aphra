import 'package:cosmetic_map/features/explore/domain/entities/place.dart';
import 'package:cosmetic_map/features/explore/data/models/place_model.dart';
import 'package:cosmetic_map/core/validation/uzbek_phone_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('places with equal values are equal', () {
    const first = Place(
      id: 1,
      name: 'Aura',
      address: 'Tashkent',
      latitude: 41.3,
      longitude: 69.2,
      rating: 4.8,
      isVerified: true,
    );
    const second = Place(
      id: 1,
      name: 'Aura',
      address: 'Tashkent',
      latitude: 41.3,
      longitude: 69.2,
      rating: 4.8,
      isVerified: true,
    );
    expect(first, second);
  });

  test('place model maps DRF decimal strings', () {
    final model = PlaceModel.fromJson({
      'id': 1,
      'name': 'Aura',
      'address': 'Tashkent',
      'latitude': '41.311081',
      'longitude': '69.240562',
      'rating': '4.8',
      'is_verified': true,
    });

    expect(model.latitude, 41.311081);
    expect(model.rating, 4.8);
  });

  test('validates Uzbekistan local phone number', () {
    expect(UzbekPhoneValidator.isValid('90 123 45 67'), isTrue);
    expect(UzbekPhoneValidator.isValid('12 123 45 67'), isFalse);
    expect(UzbekPhoneValidator.isValid('90123'), isFalse);
  });
}
