import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../models/patient_model.dart';
import '../../../providers/patient_provider.dart';
import '../../../services/image_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_widgets.dart';

class PatientRegistrationForm extends ConsumerStatefulWidget {
  final VoidCallback? onRegistrationSuccess;

  const PatientRegistrationForm({super.key, this.onRegistrationSuccess});

  @override
  ConsumerState<PatientRegistrationForm> createState() => _PatientRegistrationFormState();
}

class _PatientRegistrationFormState extends ConsumerState<PatientRegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _addressController = TextEditingController();
  final _problemController = TextEditingController();

  String _selectedSex = 'Male';
  bool _isFirstTime = true;
  DateTime? _lastConsultationDate;
  String? _capturedPhotoPath;
  bool _isSubmitting = false;

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

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _ageController.clear();
    _phone1Controller.clear();
    _phone2Controller.clear();
    _addressController.clear();
    _problemController.clear();
    setState(() {
      _selectedSex = 'Male';
      _isFirstTime = true;
      _lastConsultationDate = null;
      _capturedPhotoPath = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final path = await ImageService.pickAndSaveImage(source: source);
      if (path != null) {
        setState(() => _capturedPhotoPath = path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Capture Patient Photo',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryTeal),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primaryTeal),
                title: const Text('Choose from Photo Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_capturedPhotoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
                  title: const Text('Remove Photo', style: TextStyle(color: AppTheme.danger)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _capturedPhotoPath = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectLastConsultDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastConsultationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
      setState(() => _lastConsultationDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newPatient = Patient(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        sex: _selectedSex,
        firstTime: _isFirstTime,
        lastConsultationDate: _isFirstTime ? null : _lastConsultationDate,
        problem: _problemController.text.trim().isNotEmpty ? _problemController.text.trim() : null,
        photoPath: _capturedPhotoPath,
        phone1: _phone1Controller.text.trim(),
        phone2: _phone2Controller.text.trim(),
        address: _addressController.text.trim(),
        registrationDate: DateTime.now(),
        paymentStatus: 'Pending',
      );

      final generatedId = await ref.read(patientActionsProvider).registerPatient(newPatient);

      setState(() => _isSubmitting = false);

      if (mounted) {
        _showSuccessDialog(generatedId, newPatient.name);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering patient: $e'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(int srNo, String patientName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF065F46)),
            ),
            const SizedBox(height: 16),
            Text(
              'Patient Registered!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Serial No: ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '#$srNo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              patientName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Patient record saved securely to local clinic database.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetForm();
              if (widget.onRegistrationSuccess != null) {
                widget.onRegistrationSuccess!();
              }
            },
            child: const Text('View Patient List'),
          ),
          AppButton(
            label: 'Register Another',
            onPressed: () {
              Navigator.pop(ctx);
              _resetForm();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section Title
          Text(
            'New Patient Registration',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Fields marked with * are strictly mandatory',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Photo & Name Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Photo Section
                Center(
                  child: GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryTeal, width: 2),
                            image: _capturedPhotoPath != null && File(_capturedPhotoPath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(_capturedPhotoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _capturedPhotoPath == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 28, color: AppTheme.primaryTeal),
                                    SizedBox(height: 4),
                                    Text('Optional\nPhoto', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                  ],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Patient Full Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Patient Full Name *',
                  hint: 'e.g. Ramesh S. Sharma',
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Patient name is mandatory and cannot be empty.';
                    }
                    if (val.trim().length < 2) {
                      return 'Name must contain at least 2 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Age & Sex Row
                Row(
                  children: [
                    // Age Field
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: _ageController,
                        label: 'Age (0-120) *',
                        hint: 'e.g. 34',
                        prefixIcon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Age is required';
                          }
                          final num = int.tryParse(val.trim());
                          if (num == null || num < 0 || num > 120) {
                            return 'Valid 0-120';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Sex Dropdown
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sex *',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedSex,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.wc_outlined, size: 20, color: AppTheme.primaryTeal),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSex = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact Details Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Phone 1
                CustomTextField(
                  controller: _phone1Controller,
                  label: 'Primary Phone Number (10 Digits) *',
                  hint: 'e.g. 9876543210',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Primary phone number is mandatory.';
                    }
                    if (val.trim().length != 10) {
                      return 'Phone number must be exactly 10 digits.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Phone 2
                CustomTextField(
                  controller: _phone2Controller,
                  label: 'Secondary Phone Number (10 Digits) *',
                  hint: 'e.g. 9123456780',
                  prefixIcon: Icons.phone_iphone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Secondary phone number is mandatory.';
                    }
                    if (val.trim().length != 10) {
                      return 'Phone number must be exactly 10 digits.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Address
                CustomTextField(
                  controller: _addressController,
                  label: 'Residential / Postal Address *',
                  hint: 'Flat/Street, City, Pin Code',
                  prefixIcon: Icons.location_on_outlined,
                  maxLines: 2,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Address is mandatory and cannot be empty.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Medical & Consultation Details Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultation Details',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // First Time vs Already Consulted Radio Toggle
                Text(
                  'Visit Type *',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isFirstTime = true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _isFirstTime ? AppTheme.primaryTeal.withOpacity(0.12) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _isFirstTime ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                              width: _isFirstTime ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isFirstTime ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: _isFirstTime ? AppTheme.primaryTeal : AppTheme.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'First Time Visit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: _isFirstTime ? FontWeight.w700 : FontWeight.w500,
                                  color: _isFirstTime ? AppTheme.primaryTeal : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isFirstTime = false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: !_isFirstTime ? AppTheme.primaryTeal.withOpacity(0.12) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !_isFirstTime ? AppTheme.primaryTeal : const Color(0xFFCBD5E1),
                              width: !_isFirstTime ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                !_isFirstTime ? Icons.radio_button_checked : Icons.radio_button_off,
                                color: !_isFirstTime ? AppTheme.primaryTeal : AppTheme.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Already Consulted',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: !_isFirstTime ? FontWeight.w700 : FontWeight.w500,
                                  color: !_isFirstTime ? AppTheme.primaryTeal : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Last Consultation Date Picker (if already consulted)
                if (!_isFirstTime) ...[
                  Text(
                    'Last Consultation Date (Optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _selectLastConsultDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 20, color: AppTheme.primaryTeal),
                          const SizedBox(width: 12),
                          Text(
                            _lastConsultationDate != null
                                ? DateFormat('dd MMMM yyyy').format(_lastConsultationDate!)
                                : 'Select previous visit date',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: _lastConsultationDate != null ? AppTheme.textPrimary : AppTheme.textMuted,
                            ),
                          ),
                          const Spacer(),
                          if (_lastConsultationDate != null)
                            GestureDetector(
                              onTap: () => setState(() => _lastConsultationDate = null),
                              child: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Problem Description
                CustomTextField(
                  controller: _problemController,
                  label: 'Dental Problem / Reason for Visit (Optional)',
                  hint: 'e.g. Toothache in upper molar, routine cleaning, crown check',
                  prefixIcon: Icons.healing_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          AppButton(
            label: 'Submit Patient Registration',
            icon: Icons.person_add_alt_1_rounded,
            onPressed: _handleSubmit,
            isLoading: _isSubmitting,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
