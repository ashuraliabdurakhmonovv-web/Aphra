import 'package:cosmetic_map/features/appointments/data/datasources/appointment_mock_data_source.dart';
import 'package:cosmetic_map/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cosmetic_map/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:cosmetic_map/features/appointments/domain/usecases/get_appointments.dart';
import 'package:cosmetic_map/features/appointments/presentation/bloc/appointments_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppointmentsBloc', () {
    late AppointmentsBloc bloc;

    setUp(() {
      final source = AppointmentMockDataSourceImpl();
      final AppointmentRepository repository = AppointmentRepositoryImpl(
        source,
      );
      bloc = AppointmentsBloc(GetAppointments(repository), repository);
    });

    tearDown(() => bloc.close());

    test('loads future and history appointments separately', () async {
      bloc.add(const AppointmentsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(bloc.state.upcoming, isNotEmpty);
      expect(bloc.state.history, isNotEmpty);
    });

    test('cancelling an eligible appointment moves it to history', () async {
      bloc.add(const AppointmentsStarted());
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final appointment = bloc.state.upcoming.firstWhere(
        (item) => item.id == 'upcoming-confirmed',
      );

      bloc.add(AppointmentCancelled(appointment.id));
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(
        bloc.state.history.any((item) => item.id == appointment.id),
        isTrue,
      );
      expect(bloc.state.selectedTab, AppointmentsTab.history);
    });
  });
}
