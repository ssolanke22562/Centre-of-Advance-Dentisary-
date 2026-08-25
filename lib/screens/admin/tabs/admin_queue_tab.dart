import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/patient_model.dart';
import '../../../providers/patient_provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_widgets.dart';
import '../patient_profile_screen.dart';
import '../widgets/schedule_appointment_dialog.dart';

class AdminQueueTab extends ConsumerStatefulWidget {
  const AdminQueueTab({super.key});

  @override
  ConsumerState<AdminQueueTab> createState() => _AdminQueueTabState();
}

class _AdminQueueTabState extends ConsumerState<AdminQueueTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final currentFilter = ref.read(patientFilterProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: currentFilter.startDate != null && currentFilter.endDate != null
          ? DateTimeRange(start: currentFilter.startDate!, end: currentFilter.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(patientFilterProvider.notifier).setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final patientsAsync = ref.watch(adminPatientsProvider);
    final filterState = ref.watch(patientFilterProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminPatientsProvider);
        ref.invalidate(dashboardStatsProvider);
      },
      color: AppTheme.primaryTeal,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. Dashboard Analytics Summary Cards
          statsAsync.when(
            data: (stats) => Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Total Patients',
                    value: stats.totalPatients.toString(),
                    icon: Icons.people_alt_outlined,
                    color: AppTheme.primaryTeal,
                    backgroundColor: const Color(0xFFE0F2FE),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: "Today's Appts",
                    value: stats.todayAppointments.toString(),
                    icon: Icons.calendar_today,
                    color: AppTheme.info,
                    backgroundColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Pending Due',
                    value: stats.pendingPayments.toString(),
                    icon: Icons.pending_actions,
                    color: AppTheme.warning,
                    backgroundColor: const Color(0xFFFEF3C7),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: LinearProgressIndicator(color: AppTheme.primaryTeal)),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),

          // 2. Search & Filter Bar
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Text Search
                TextField(
                  controller: _searchController,
                  onChanged: (val) => ref.read(patientFilterProvider.notifier).setQuery(val),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by Patient Name, Phone or Sr. No...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
                    suffixIcon: filterState.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(patientFilterProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Payment Status Filter Chips & Date Filter Button
                Row(
                  children: [
                    // Payment Filter Chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', filterState.paymentStatus == 'All'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Pending', filterState.paymentStatus == 'Pending'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Paid', filterState.paymentStatus == 'Paid'),
                          ],
                        ),
                      ),
                    ),

                    // Date Range Filter Button
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: Icon(
                        Icons.date_range,
                        size: 15,
                        color: filterState.startDate != null ? AppTheme.primaryTeal : AppTheme.textSecondary,
                      ),
                      label: Text(
                        filterState.startDate != null
                            ? '${DateFormat('MM/dd').format(filterState.startDate!)} - ${DateFormat('MM/dd').format(filterState.endDate!)}'
                            : 'Date Range',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: filterState.startDate != null ? AppTheme.primaryTeal : AppTheme.textSecondary,
                          fontWeight: filterState.startDate != null ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: filterState.startDate != null ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),

                    // Clear Filters button if any filter active
                    if (filterState.startDate != null || filterState.paymentStatus != 'All' || filterState.query.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.filter_alt_off_outlined, size: 18, color: AppTheme.danger),
                        tooltip: 'Reset all filters',
                        onPressed: () {
                          _searchController.clear();
                          ref.read(patientFilterProvider.notifier).resetFilters();
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Queue List
          patientsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              ),
            ),
            error: (err, _) => Center(
              child: Text(
                'Error loading queue: $err',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.danger),
              ),
            ),
            data: (patients) {
              if (patients.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: filterState.query.isNotEmpty || filterState.paymentStatus != 'All'
                      ? 'No Patients Match Filters'
                      : 'No Registered Patients in Clinic Queue',
                  description: filterState.query.isNotEmpty || filterState.paymentStatus != 'All'
                      ? 'Try clearing the search query or payment filters.'
                      : 'Patients registered from the front desk reception will appear here.',
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: patients.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return _buildQueueCard(patient);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryTeal,
      backgroundColor: const Color(0xFFF1F5F9),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      onSelected: (selected) {
        if (selected) {
          ref.read(patientFilterProvider.notifier).setPaymentStatus(label);
        }
      },
    );
  }

  Widget _buildQueueCard(Patient patient) {
    final isPaid = patient.paymentStatus == 'Paid';

    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientProfileScreen(patientId: patient.id!),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Serial Number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${patient.id}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Patient Name
              Expanded(
                child: Text(
                  patient.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),

              // Payment Status Toggle Button
              InkWell(
                onTap: () async {
                  await ref.read(patientActionsProvider).togglePaymentStatus(
                        patient.id!,
                        patient.paymentStatus,
                      );
                },
                borderRadius: BorderRadius.circular(20),
                child: isPaid ? StatusBadge.paid() : StatusBadge.pending(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Demographics & Contact Line
          Row(
            children: [
              Text(
                '${patient.age} yrs • ${patient.sex}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                patient.phone1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 18),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reg: ${patient.formattedRegDate}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ScheduleAppointmentDialog(
                          preSelectedPatientId: patient.id,
                          preSelectedPatientName: patient.name,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_alarm_rounded, size: 15),
                    label: const Text('Schedule'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppTheme.primaryTeal),
                      foregroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
