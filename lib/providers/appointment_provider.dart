import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/appointment_model.dart';
import 'patient_provider.dart';
import 'stats_provider.dart';

final allAppointmentsProvider =
    FutureProvider.autoDispose<List<Appointment>>((ref) async {
  return await DatabaseHelper.instance.getAllAppointments();
});

final appointmentsForDateProvider =
    FutureProvider.family.autoDispose<List<Appointment>, DateTime>((ref, date) async {
  return await DatabaseHelper.instance.getAppointmentsForDate(date);
});

class AppointmentActionsNotifier {
  final Ref ref;
  AppointmentActionsNotifier(this.ref);

  Future<List<Appointment>> checkConflict(DateTime dateTime, {int? excludeAppointmentId}) async {
    return await DatabaseHelper.instance.checkAppointmentConflict(
      dateTime,
      excludeAppointmentId: excludeAppointmentId,
    );
  }

  Future<int> scheduleAppointment(Appointment appointment) async {
    final id = await DatabaseHelper.instance.insertAppointment(appointment);
    _invalidateAll();
    return id;
  }

  Future<void> deleteAppointment(int appointmentId) async {
    await DatabaseHelper.instance.deleteAppointment(appointmentId);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidate(allAppointmentsProvider);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(adminPatientsProvider);
  }
}

final appointmentActionsProvider = Provider<AppointmentActionsNotifier>((ref) {
  return AppointmentActionsNotifier(ref);
});
