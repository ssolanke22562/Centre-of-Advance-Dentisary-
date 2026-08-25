import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/appointment_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_widgets.dart';
import '../patient_profile_screen.dart';
import '../widgets/schedule_appointment_dialog.dart';

class AdminScheduleTab extends ConsumerStatefulWidget {
  const AdminScheduleTab({super.key});

  @override
  ConsumerState<AdminScheduleTab> createState() => _AdminScheduleTabState();
}

class _AdminScheduleTabState extends ConsumerState<AdminScheduleTab> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickCalendarDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      setState(() => _selectedDate = picked);
    }
  }

  void _showCancelAppointmentDialog(Appointment appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text('Are you sure you want to cancel the appointment for ${appt.patientName ?? "Patient"} on ${appt.formattedDateTime}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(appointmentActionsProvider).deleteAppointment(appt.id!);
            },
            child: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentsForDateProvider(_selectedDate));
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Date Selector Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.primaryTeal),
                  onPressed: () {
                    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                  },
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickCalendarDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: AppTheme.primaryTeal),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (isToday)
                            Text(
                              "Today's Schedule",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.primaryTeal),
                  onPressed: () {
                    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                  },
                ),
              ],
            ),
          ),

          // Appointments Timeline List
          Expanded(
            child: appointmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
              error: (err, _) => Center(child: Text('Error loading schedule: $err')),
              data: (appointments) {
                if (appointments.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_available_outlined,
                    title: 'No Appointments Scheduled',
                    description: 'No patient appointments booked for ${DateFormat('MMM dd, yyyy').format(_selectedDate)}.',
                    action: AppButton(
                      label: 'Book Appointment',
                      icon: Icons.add,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const ScheduleAppointmentDialog(),
                        );
                      },
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(appointmentsForDateProvider(_selectedDate)),
                  color: AppTheme.primaryTeal,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: appointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final appt = appointments[index];
                      return _buildAppointmentCard(appt);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const ScheduleAppointmentDialog(),
          );
        },
        backgroundColor: AppTheme.primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Book Slot',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appt) {
    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientProfileScreen(patientId: appt.patientId),
          ),
        );
      },
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              children: [
                const Icon(Icons.access_time_filled, size: 16, color: AppTheme.info),
                const SizedBox(height: 4),
                Text(
                  appt.formattedTime,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.info,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Patient Name & Notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appt.patientName ?? 'Patient #${appt.patientId}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appt.notes != null && appt.notes!.isNotEmpty
                      ? appt.notes!
                      : 'General dental checkup / consultation',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Cancel button
          IconButton(
            icon: const Icon(Icons.cancel_outlined, size: 20, color: AppTheme.danger),
            tooltip: 'Cancel slot',
            onPressed: () => _showCancelAppointmentDialog(appt),
          ),
        ],
      ),
    );
  }
}
