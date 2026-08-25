import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';

class DashboardStats {
  final int totalPatients;
  final int pendingPayments;
  final int todayAppointments;

  DashboardStats({
    this.totalPatients = 0,
    this.pendingPayments = 0,
    this.todayAppointments = 0,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final data = await DatabaseHelper.instance.getDashboardAnalytics();
  return DashboardStats(
    totalPatients: data['totalPatients'] ?? 0,
    pendingPayments: data['pendingPayments'] ?? 0,
    todayAppointments: data['todayAppointments'] ?? 0,
  );
});
