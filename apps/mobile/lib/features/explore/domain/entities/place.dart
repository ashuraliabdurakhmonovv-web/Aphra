import 'package:equatable/equatable.dart';

class Place extends Equatable {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.isVerified,
  });
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final bool isVerified;

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    latitude,
    longitude,
    rating,
    isVerified,
  ];
}
