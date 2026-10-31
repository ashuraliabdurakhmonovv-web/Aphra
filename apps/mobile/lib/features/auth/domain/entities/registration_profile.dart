import 'package:equatable/equatable.dart';

enum UserGender { female, male }

class RegistrationProfile extends Equatable {
  const RegistrationProfile({
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
  });

  final String phone;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final UserGender gender;

  @override
  List<Object> get props => [phone, firstName, lastName, birthDate, gender];
}
