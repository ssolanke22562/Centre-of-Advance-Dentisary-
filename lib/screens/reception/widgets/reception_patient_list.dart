import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../models/patient_model.dart';
import '../../../providers/patient_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_widgets.dart';
import 'reception_edit_dialog.dart';

class ReceptionPatientList extends ConsumerStatefulWidget {
  const ReceptionPatientList({super.key});

  @override
  ConsumerState<ReceptionPatientList> createState() => _ReceptionPatientListState();
}

class _ReceptionPatientListState extends ConsumerState<ReceptionPatientList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minimalPatientsAsync = ref.watch(receptionPatientsProvider);

    return Column(
      children: [
        // Search bar for front desk lookup
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by Sr. No or Patient Name...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),

        // List Header & Security notice
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.privacy_tip_outlined, size: 15, color: AppTheme.primaryTeal),
              const SizedBox(width: 6),
              Text(
                'Reception View (Sr. No & Patient Name Only)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: AppTheme.primaryTeal),
                tooltip: 'Refresh list',
                onPressed: () => ref.invalidate(receptionPatientsProvider),
              ),
            ],
          ),
        ),

        // Patient List
        Expanded(
          child: minimalPatientsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            ),
            error: (err, _) => Center(
              child: Text(
                'Error loading patients: $err',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.danger),
              ),
            ),
            data: (patients) {
              final filtered = patients.where((p) {
                if (_searchQuery.isEmpty) return true;
                return p.name.toLowerCase().contains(_searchQuery) ||
                    p.id.toString().contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.person_off_outlined,
                  title: _searchQuery.isEmpty ? 'No Patients Registered' : 'No Matches Found',
                  description: _searchQuery.isEmpty
                      ? 'Registered patients will appear in this minimal desk list.'
                      : 'Try searching with a different name or Sr. Number.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(receptionPatientsProvider),
                color: AppTheme.primaryTeal,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final patient = filtered[index];
                    return _buildMinimalPatientCard(patient);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalPatientCard(MinimalPatient patient) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Serial Number Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7DD3FC)),
            ),
            child: Center(
              child: Text(
                '#${patient.id}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0369A1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Patient Name & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reg: ${DateFormat('dd MMM, hh:mm a').format(patient.registrationDate)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Grace Edit action button if eligible
          if (patient.isEligibleForGraceEdit)
            Tooltip(
              message: 'Correct typo (Grace window active)',
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => ReceptionEditDialog(patient: patient),
                  );
                },
                icon: const Icon(Icons.edit, size: 14),
                label: const Text('Edit Name'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppTheme.primaryTeal,
                  side: const BorderSide(color: AppTheme.primaryTeal),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
