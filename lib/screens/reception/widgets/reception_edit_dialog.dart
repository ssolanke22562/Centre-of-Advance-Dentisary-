import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/patient_model.dart';
import '../../../providers/patient_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_widgets.dart';

class ReceptionEditDialog extends ConsumerStatefulWidget {
  final MinimalPatient patient;

  const ReceptionEditDialog({super.key, required this.patient});

  @override
  ConsumerState<ReceptionEditDialog> createState() => _ReceptionEditDialogState();
}

class _ReceptionEditDialogState extends ConsumerState<ReceptionEditDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final success = await ref
        .read(patientActionsProvider)
        .updatePatientNameByReception(widget.patient.id, _nameController.text.trim());
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Patient name updated successfully.' : 'Failed to update patient name.',
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
              color: AppTheme.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryTeal, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            'Grace Edit: Sr. #${widget.patient.id}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You can correct typographical errors in the patient\'s name immediately after submission.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nameController,
              label: 'Patient Full Name',
              hint: 'Enter corrected name',
              prefixIcon: Icons.person_outline,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Patient name cannot be empty';
                }
                return null;
              },
            ),
          ],
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
          label: 'Save Correction',
          onPressed: _handleSave,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
