import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/patient_model.dart';
import '../../../providers/patient_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_widgets.dart';

class EditPatientDialog extends ConsumerStatefulWidget {
  final Patient patient;

  const EditPatientDialog({super.key, required this.patient});

  @override
  ConsumerState<EditPatientDialog> createState() => _EditPatientDialogState();
}

class _EditPatientDialogState extends ConsumerState<EditPatientDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phone1Controller;
  late TextEditingController _phone2Controller;
  late TextEditingController _addressController;
  late TextEditingController _problemController;

  late String _selectedSex;
  late String _paymentStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
    _ageController = TextEditingController(text: widget.patient.age.toString());
    _phone1Controller = TextEditingController(text: widget.patient.phone1);
    _phone2Controller = TextEditingController(text: widget.patient.phone2);
    _addressController = TextEditingController(text: widget.patient.address);
    _problemController = TextEditingController(text: widget.patient.problem ?? '');
    _selectedSex = widget.patient.sex;
    _paymentStatus = widget.patient.paymentStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _addressController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final updatedPatient = widget.patient.copyWith(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        sex: _selectedSex,
        phone1: _phone1Controller.text.trim(),
        phone2: _phone2Controller.text.trim(),
        address: _addressController.text.trim(),
        problem: _problemController.text.trim().isNotEmpty ? _problemController.text.trim() : null,
        paymentStatus: _paymentStatus,
      );

      await ref.read(patientActionsProvider).updatePatientByAdmin(updatedPatient);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient record updated successfully.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating patient: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryTeal, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Edit Record (Sr. #${widget.patient.id})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Patient Full Name *',
                  prefixIcon: Icons.person_outline,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Age *',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validator: (val) {
                          final num = int.tryParse(val ?? '');
                          if (num == null || num < 0 || num > 120) return '0-120';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sex *', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedSex,
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) => setState(() => _selectedSex = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _phone1Controller,
                  label: 'Primary Phone (10 Digits) *',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (val) => val != null && val.trim().length == 10 ? null : '10 digits required',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _phone2Controller,
                  label: 'Secondary Phone (10 Digits) *',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (val) => val != null && val.trim().length == 10 ? null : '10 digits required',
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address *',
                  maxLines: 2,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _problemController,
                  label: 'Problem Description (Optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                Text('Payment Status', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _paymentStatus,
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  ],
                  onChanged: (v) => setState(() => _paymentStatus = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          label: 'Save Changes',
          onPressed: _handleSave,
          isLoading: _isSaving,
        ),
      ],
    );
  }
}
