import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/appointment_model.dart';
import '../../models/patient_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/patient_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_widgets.dart';
import 'widgets/edit_patient_dialog.dart';
import 'widgets/schedule_appointment_dialog.dart';

class PatientProfileScreen extends ConsumerStatefulWidget {
  final int patientId;

  const PatientProfileScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  void _showDeleteConfirmation(Patient patient) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppTheme.danger),
            const SizedBox(width: 8),
            Text(
              'Soft-Delete Patient Record',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the record for "${patient.name}" (Sr. #${patient.id})?\n\nThis record will be safely flagged as inactive to preserve historical appointment consistency and export logs.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(patientActionsProvider).softDeletePatient(patient.id!);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Patient record moved to inactive / soft-deleted.'),
                    backgroundColor: AppTheme.warning,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAppointmentConfirmation(Appointment appt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text('Cancel scheduled appointment for ${appt.formattedDateTime}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(appointmentActionsProvider).deleteAppointment(appt.id!);
              ref.invalidate(patientDetailProvider(widget.patientId));
            },
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientDetailProvider(widget.patientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient Record',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        actions: [
          patientAsync.when(
            data: (patient) {
              if (patient == null) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryTeal),
                    tooltip: 'Edit Patient Details',
                    onPressed: () async {
                      final updated = await showDialog(
                        context: context,
                        builder: (_) => EditPatientDialog(patient: patient),
                      );
                      if (updated == true) {
                        ref.invalidate(patientDetailProvider(widget.patientId));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                    tooltip: 'Soft Delete Record',
                    onPressed: () => _showDeleteConfirmation(patient),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
        data: (patient) {
          if (patient == null) {
            return const EmptyStateWidget(
              icon: Icons.person_off,
              title: 'Record Not Found',
              description: 'This patient record may have been deleted.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Card
                AppCard(
                  child: Row(
                    children: [
                      // Photo / Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE0F2FE),
                          border: Border.all(color: AppTheme.primaryTeal, width: 2),
                          image: patient.photoPath != null && File(patient.photoPath!).existsSync()
                              ? DecorationImage(
                                  image: FileImage(File(patient.photoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: patient.photoPath == null || !File(patient.photoPath!).existsSync()
                            ? Center(
                                child: Text(
                                  patient.name.isNotEmpty ? patient.name.substring(0, 1).toUpperCase() : 'P',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 18),

                      // Name, Sr No, Age & Sex
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Sr. #${patient.id}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryTeal,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (patient.paymentStatus == 'Paid')
                                  StatusBadge.paid()
                                else
                                  StatusBadge.pending(),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              patient.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${patient.age} yrs • ${patient.sex} • Registered ${patient.formattedRegDate}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Status Quick Toggle Action
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: patient.paymentStatus == 'Paid'
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          patient.paymentStatus == 'Paid' ? Icons.check_circle : Icons.pending_actions,
                          color: patient.paymentStatus == 'Paid' ? const Color(0xFF065F46) : const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Billing & Payment Status',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Current status: ${patient.paymentStatus}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppButton(
                        label: patient.paymentStatus == 'Pending' ? 'Mark Paid' : 'Set Pending',
                        backgroundColor: patient.paymentStatus == 'Pending' ? AppTheme.success : AppTheme.warning,
                        onPressed: () async {
                          await ref.read(patientActionsProvider).togglePaymentStatus(patient.id!, patient.paymentStatus);
                          ref.invalidate(patientDetailProvider(widget.patientId));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contact & Address Details
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact & Location',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(Icons.phone_outlined, 'Primary Phone', patient.phone1),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.phone_iphone_outlined, 'Secondary Phone', patient.phone2),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.location_on_outlined, 'Address', patient.address),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Clinical Case Details
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Consultation Info',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        Icons.medical_information_outlined,
                        'Consultation Type',
                        patient.firstTime ? 'First Time Visit' : 'Returning Patient (Previously Consulted)',
                      ),
                      if (!patient.firstTime) ...[
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          Icons.calendar_month_outlined,
                          'Last Consultation Date',
                          patient.formattedLastConsultation,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        Icons.healing_outlined,
                        'Chief Complaint / Problem',
                        patient.problem ?? 'No specific problem description recorded.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Appointments Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appointment History (${patient.appointments.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final scheduled = await showDialog(
                          context: context,
                          builder: (_) => ScheduleAppointmentDialog(
                            preSelectedPatientId: patient.id,
                            preSelectedPatientName: patient.name,
                          ),
                        );
                        if (scheduled == true) {
                          ref.invalidate(patientDetailProvider(widget.patientId));
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Schedule'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: AppTheme.primaryTeal),
                        foregroundColor: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Appointments List
                if (patient.appointments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'No past or upcoming appointments recorded for this patient.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  )
                else
                  ...patient.appointments.map((appt) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryTeal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.calendar_today, color: AppTheme.primaryTeal, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appt.formattedDateTime,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        appt.notes!,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: AppTheme.danger),
                                tooltip: 'Cancel appointment',
                                onPressed: () => _showDeleteAppointmentConfirmation(appt),
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryTeal),
        const SizedBox(width: 10),
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
