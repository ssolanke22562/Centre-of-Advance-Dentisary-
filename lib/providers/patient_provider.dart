import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/patient_model.dart';
import 'stats_provider.dart';

// -------------------------------------------------------------
// FILTER STATE
// -------------------------------------------------------------
class PatientFilterState {
  final String query;
  final String paymentStatus; // 'All' | 'Pending' | 'Paid'
  final DateTime? startDate;
  final DateTime? endDate;

  PatientFilterState({
    this.query = '',
    this.paymentStatus = 'All',
    this.startDate,
    this.endDate,
  });

  PatientFilterState copyWith({
    String? query,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
  }) {
    return PatientFilterState(
      query: query ?? this.query,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

class PatientFilterNotifier extends StateNotifier<PatientFilterState> {
  PatientFilterNotifier() : super(PatientFilterState());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setPaymentStatus(String s) => state = state.copyWith(paymentStatus: s);
  void setDateRange(DateTime? start, DateTime? end) =>
      state = state.copyWith(startDate: start, endDate: end);
  void resetFilters() => state = PatientFilterState();
}

final patientFilterProvider =
    StateNotifierProvider<PatientFilterNotifier, PatientFilterState>((ref) {
  return PatientFilterNotifier();
});

// -------------------------------------------------------------
// RECEPTION PATIENT LIST (DATA LAYER PRIVACY ENFORCED)
// -------------------------------------------------------------
final receptionPatientsProvider =
    FutureProvider.autoDispose<List<MinimalPatient>>((ref) async {
  return await DatabaseHelper.instance.getMinimalPatientsForReception();
});

// -------------------------------------------------------------
// ADMIN PATIENT QUEUE (FULL ACCESS + FILTERED)
// -------------------------------------------------------------
final adminPatientsProvider =
    FutureProvider.autoDispose<List<Patient>>((ref) async {
  final filter = ref.watch(patientFilterProvider);
  return await DatabaseHelper.instance.getAllPatients(
    query: filter.query,
    paymentStatus: filter.paymentStatus,
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

// Single patient detail provider
final patientDetailProvider =
    FutureProvider.family.autoDispose<Patient?, int>((ref, patientId) async {
  return await DatabaseHelper.instance.getPatientById(patientId);
});

// -------------------------------------------------------------
// PATIENT ACTIONS CONTROLLER
// -------------------------------------------------------------
class PatientActionsNotifier {
  final Ref ref;
  PatientActionsNotifier(this.ref);

  Future<int> registerPatient(Patient patient) async {
    final id = await DatabaseHelper.instance.insertPatient(patient);
    _invalidateAll();
    return id;
  }

  Future<bool> updatePatientNameByReception(int id, String newName) async {
    final success = await DatabaseHelper.instance.updatePatientNameByReception(id, newName);
    if (success) {
      _invalidateAll();
    }
    return success;
  }

  Future<int> updatePatientByAdmin(Patient patient) async {
    final count = await DatabaseHelper.instance.updatePatient(patient);
    _invalidateAll();
    return count;
  }

  Future<void> togglePaymentStatus(int id, String currentStatus) async {
    final newStatus = currentStatus == 'Pending' ? 'Paid' : 'Pending';
    await DatabaseHelper.instance.togglePaymentStatus(id, newStatus);
    _invalidateAll();
  }

  Future<void> softDeletePatient(int id) async {
    await DatabaseHelper.instance.softDeletePatient(id);
    _invalidateAll();
  }

  void _invalidateAll() {
    ref.invalidate(receptionPatientsProvider);
    ref.invalidate(adminPatientsProvider);
    ref.invalidate(dashboardStatsProvider);
  }
}

final patientActionsProvider = Provider<PatientActionsNotifier>((ref) {
  return PatientActionsNotifier(ref);
});
