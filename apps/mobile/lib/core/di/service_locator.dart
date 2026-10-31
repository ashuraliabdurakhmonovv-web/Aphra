import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_local_profile.dart';
import '../../features/auth/domain/usecases/save_registration_profile.dart';
import '../../features/auth/presentation/bloc/auth_onboarding_bloc.dart';
import '../../features/appointments/data/datasources/appointment_mock_data_source.dart';
import '../../features/appointments/data/repositories/appointment_repository_impl.dart';
import '../../features/appointments/domain/repositories/appointment_repository.dart';
import '../../features/appointments/domain/usecases/get_appointments.dart';
import '../../features/appointments/presentation/bloc/appointments_bloc.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/explore/data/datasources/place_local_data_source.dart';
import '../../features/explore/data/datasources/place_remote_data_source.dart';
import '../../features/explore/data/models/place_model.dart';
import '../../features/explore/data/repositories/place_repository_impl.dart';
import '../../features/explore/domain/repositories/place_repository.dart';
import '../../features/explore/domain/usecases/get_places.dart';
import '../../features/explore/presentation/bloc/explore_bloc.dart';
import '../network/dio_client.dart';
import '../platform/maps_launcher.dart';
import '../storage/preferences_service.dart';
import '../storage/secure_storage_service.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlaceModelAdapter());
  final placesBox = await Hive.openBox<PlaceModel>('places');
  final authBox = await Hive.openBox<dynamic>('auth_profile');
  final preferences = await SharedPreferences.getInstance();
  sl
    ..registerLazySingleton(() => const FlutterSecureStorage())
    ..registerLazySingleton<SecureStorageService>(
      () => SecureStorageServiceImpl(sl()),
    )
    ..registerLazySingleton<PreferencesService>(
      () => PreferencesServiceImpl(preferences),
    )
    ..registerLazySingleton<MapsLauncher>(GoogleMapsLauncher.new)
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(authBox),
    )
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()))
    ..registerLazySingleton(() => GetLocalProfile(sl()))
    ..registerLazySingleton(() => SaveRegistrationProfile(sl()))
    ..registerFactory(() => AuthOnboardingBloc(sl()))
    ..registerFactory(() => ProfileBloc(sl(), sl()))
    ..registerLazySingleton<AppointmentMockDataSource>(
      AppointmentMockDataSourceImpl.new,
    )
    ..registerLazySingleton<AppointmentRepository>(
      () => AppointmentRepositoryImpl(sl()),
    )
    ..registerLazySingleton(() => GetAppointments(sl()))
    ..registerFactory(() => AppointmentsBloc(sl(), sl()))
    ..registerLazySingleton(() => DioClient(secureStorage: sl()).dio)
    ..registerLazySingleton<PlaceRemoteDataSource>(
      () => PlaceRemoteDataSourceImpl(sl()),
    )
    ..registerLazySingleton<PlaceLocalDataSource>(
      () => PlaceLocalDataSourceImpl(placesBox),
    )
    ..registerLazySingleton<PlaceRepository>(
      () => PlaceRepositoryImpl(remote: sl(), local: sl()),
    )
    ..registerLazySingleton(() => GetPlaces(sl()))
    ..registerFactory(() => ExploreBloc(sl()));
}
