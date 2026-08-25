import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/export_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_widgets.dart';

class AdminExportTab extends StatefulWidget {
  const AdminExportTab({super.key});

  @override
  State<AdminExportTab> createState() => _AdminExportTabState();
}

class _AdminExportTabState extends State<AdminExportTab> {
  bool _isExportingCSV = false;
  bool _isExportingDB = false;

  Future<void> _handleExportCSV() async {
    setState(() => _isExportingCSV = true);
    try {
      final filePath = await ExportService.exportPatientsToCSV();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV ready & opened in share sheet.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingCSV = false);
    }
  }

  Future<void> _handleExportBackup() async {
    setState(() => _isExportingDB = true);
    try {
      final filePath = await ExportService.exportDatabaseBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database backup file opened in share sheet.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExportingDB = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Title & Description
        Text(
          'Data Export & Clinic Backup',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Export patient history, appointments, and generate encrypted local SQLite backups.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // 1. CSV Data Export Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: Color(0xFF065F46), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Full Patient Database (CSV)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Includes all non-deleted patients, contact details, payment statuses, and appointment logs.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                'Included Columns:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Sr.No • Name • Age • Sex • FirstTime • LastConsultationDate • Problem • Phone1 • Phone2 • Address • RegistrationDate • PaymentStatus • AppointmentDate • AppointmentNotes',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Export & Share CSV',
                icon: Icons.share_rounded,
                backgroundColor: const Color(0xFF059669),
                onPressed: _handleExportCSV,
                isLoading: _isExportingCSV,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Database Backup Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storage_rounded, color: AppTheme.info, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export SQLite Database Backup',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Generates a raw copy of the local clinic database file for archival and migration.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Create DB Backup',
                icon: Icons.save_alt_rounded,
                backgroundColor: AppTheme.primaryTeal,
                onPressed: _handleExportBackup,
                isLoading: _isExportingDB,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Storage & Offline Architecture Notice
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppTheme.primaryDark, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Offline Storage & Privacy Notice',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• All clinic records reside 100% locally on this device in SQLite.\n• Files are exported via the system share sheet (compatible with Android 13+ scoped storage and iOS Files app).\n• Perform periodic backups to ensure patient records are preserved in case of device replacement.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
