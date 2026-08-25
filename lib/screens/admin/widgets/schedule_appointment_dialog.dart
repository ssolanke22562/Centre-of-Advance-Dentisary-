import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/appointment_model.dart';
import '../../../models/patient_model.dart';
import '../../../providers/appointment_provider.dart';
import '../../../providers/patient_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_widgets.dart';

class ScheduleAppointmentDialog extends ConsumerStatefulWidget {
  final int? preSelectedPatientId;
  final String? preSelectedPatientName;

  const ScheduleAppointmentDialog({
    super.key,
    this.preSelectedPatientId,
    this.preSelectedPatientName,
  });

  @override
  ConsumerState<ScheduleAppointmentDialog> createState() => _ScheduleAppointmentDialogState();
}

class _ScheduleAppointmentDialogState extends ConsumerState<ScheduleAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  int? _selectedPatientId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  List<Appointment> _conflicts = [];
  bool _isCheckingConflict = false;
  bool _isBooking = false;
  bool _overrideConflictWarning = false;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.preSelectedPatientId;
    // Align time to next 15-minute slot
    final now = DateTime.now();
    final nextMinute = ((now.minute / 15).ceil() * 15) % 60;
    _selectedTime = TimeOfDay(hour: now.hour, minute: nextMinute);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _combinedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _checkDoubleBookingConflict() async {
    setState(() {
      _isCheckingConflict = true;
      _conflicts = [];
    });

    final conflicts = await ref
        .read(appointmentActionsProvider)
        .checkConflict(_combinedDateTime);

    if (mounted) {
      setState(() {
        _conflicts = conflicts;
        _isCheckingConflict = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
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
      await _checkDoubleBookingConflict();
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
      setState(() => _selectedTime = picked);
      await _checkDoubleBookingConflict();
    }
  }

  Future<void> _handleBookAppointment() async {
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a patient.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check conflicts
    final conflicts = await ref
        .read(appointmentActionsProvider)
        .checkConflict(_combinedDateTime);

    if (conflicts.isNotEmpty && !_overrideConflictWarning) {
      setState(() {
        _conflicts = conflicts;
      });
      return;
    }

    setState(() => _isBooking = true);

    try {
      final appointment = Appointment(
        patientId: _selectedPatientId!,
        dateTime: _combinedDateTime,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      await ref.read(appointmentActionsProvider).scheduleAppointment(appointment);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment scheduled successfully.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPatientsAsync = ref.watch(adminPatientsProvider);

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryTeal, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Schedule Appointment',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Selection Dropdown
                Text(
                  'Select Patient *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                allPatientsAsync.when(
                  loading: () => const LinearProgressIndicator(color: AppTheme.primaryTeal),
                  error: (_, __) => const Text('Error loading patients'),
                  data: (patients) {
                    if (patients.isEmpty) {
                      return const Text('No patients registered yet.');
                    }

                    // Check if pre-selected ID exists in list
                    final currentId = _selectedPatientId ??
                        (patients.isNotEmpty ? patients.first.id : null);

                    return DropdownButtonFormField<int>(
                      value: currentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.primaryTeal),
                      ),
                      items: patients.map((p) {
                        return DropdownMenuItem<int>(
                          value: p.id,
                          child: Text(
                            '#${p.id} - ${p.name} (${p.phone1})',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedPatientId = val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Date & Time Picker Buttons
                Row(
                  children: [
                    // Date Picker
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryTeal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Time Picker
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Slot *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16, color: AppTheme.primaryTeal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedTime.format(context),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // DOUBLE-BOOKING CONFLICT WARNING BOX
                if (_conflicts.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Double-Booking Slot Warning',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'An appointment is already scheduled within ±30 minutes:',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF991B1B)),
                        ),
                        const SizedBox(height: 6),
                        ..._conflicts.map((c) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${c.patientName ?? "Patient"} at ${c.formattedTime}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF7F1D1D),
                                ),
                              ),
                            )),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _overrideConflictWarning,
                              activeColor: AppTheme.danger,
                              onChanged: (val) {
                                setState(() => _overrideConflictWarning = val ?? false);
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Allow intentional double-booking for this slot',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes / Procedure field
                CustomTextField(
                  controller: _notesController,
                  label: 'Appointment Notes / Procedure (Optional)',
                  hint: 'e.g. RCT Sitting 1, Composite Restoration, Extraction',
                  prefixIcon: Icons.notes_outlined,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        AppButton(
          label: _conflicts.isNotEmpty && !_overrideConflictWarning
              ? 'Check Time'
              : 'Confirm Booking',
          onPressed: _handleBookAppointment,
          isLoading: _isBooking,
        ),
      ],
    );
  }
}
