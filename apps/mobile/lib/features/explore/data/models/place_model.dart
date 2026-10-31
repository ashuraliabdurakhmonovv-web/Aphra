import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/place.dart';

part 'place_model.freezed.dart';
part 'place_model.g.dart';

@freezed
abstract class PlaceModel with _$PlaceModel {
  const PlaceModel._();
  const factory PlaceModel({
    required int id,
    required String name,
    required String address,
    @JsonKey(fromJson: _decimalToDouble) required double latitude,
    @JsonKey(fromJson: _decimalToDouble) required double longitude,
    @JsonKey(fromJson: _decimalToDouble) required double rating,
    @JsonKey(name: 'is_verified') required bool isVerified,
  }) = _PlaceModel;
  factory PlaceModel.fromJson(Map<String, dynamic> json) =>
      _$PlaceModelFromJson(json);

  Place toEntity() => Place(
    id: id,
    name: name,
    address: address,
    latitude: latitude,
    longitude: longitude,
    rating: rating,
    isVerified: isVerified,
  );
}

double _decimalToDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw const FormatException('Expected a decimal value');
}

class PlaceModelAdapter extends TypeAdapter<PlaceModel> {
  @override
  final int typeId = 1;
  @override
  PlaceModel read(BinaryReader reader) => PlaceModel(
    id: reader.readInt(),
    name: reader.readString(),
    address: reader.readString(),
    latitude: reader.readDouble(),
    longitude: reader.readDouble(),
    rating: reader.readDouble(),
    isVerified: reader.readBool(),
  );
  @override
  void write(BinaryWriter writer, PlaceModel object) => writer
    ..writeInt(object.id)
    ..writeString(object.name)
    ..writeString(object.address)
    ..writeDouble(object.latitude)
    ..writeDouble(object.longitude)
    ..writeDouble(object.rating)
    ..writeBool(object.isVerified);
}
