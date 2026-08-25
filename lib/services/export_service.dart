import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';

class ExportService {
  /// Generates RFC-compliant CSV and invokes native share sheet via share_plus
  static Future<String> exportPatientsToCSV() async {
    final rawData = await DatabaseHelper.instance.getJoinedExportData();

    if (rawData.isEmpty) {
      throw Exception('No patient records found to export.');
    }

    final List<List<dynamic>> csvRows = [];

    // 1. CSV Header Row
    csvRows.add([
      'Sr.No',
      'Name',
      'Age',
      'Sex',
      'FirstTime',
      'LastConsultationDate',
      'Problem',
      'Phone1',
      'Phone2',
      'Address',
      'RegistrationDate',
      'PaymentStatus',
      'AppointmentDate',
      'AppointmentNotes',
    ]);

    // 2. Data Rows
    for (var row in rawData) {
      final regDateStr = row['registration_date'] != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(row['registration_date'] as String))
          : '';
      
      final lastConsultStr = row['last_consultation_date'] != null && (row['last_consultation_date'] as String).isNotEmpty
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(row['last_consultation_date'] as String))
          : '';

      final apptDateStr = row['appointment_date'] != null && (row['appointment_date'] as String).isNotEmpty
          ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(row['appointment_date'] as String))
          : '';

      csvRows.add([
        row['sr_no'] ?? '',
        row['patient_name'] ?? '',
        row['age'] ?? '',
        row['sex'] ?? '',
        (row['first_time'] == 1) ? 'Yes' : 'No',
        lastConsultStr,
        row['problem'] ?? '',
        row['phone1'] ?? '',
        row['phone2'] ?? '',
        row['address'] ?? '',
        regDateStr,
        row['payment_status'] ?? 'Pending',
        apptDateStr,
        row['appointment_notes'] ?? '',
      ]);
    }

    // Convert to CSV String
    final csvString = const ListToCsvConverter().convert(csvRows);

    // Save to App Cache / Temporary directory
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'DrPatil_Patients_Export_$timestamp.csv';
    final filePath = p.join(tempDir.path, fileName);

    final file = File(filePath);
    await file.writeAsString(csvString);

    // Share via share_plus
    final result = await Share.shareXFiles(
      [XFile(filePath, mimeType: 'text/csv', name: fileName)],
      subject: 'Dr. Patil Clinic Patient Export ($timestamp)',
      text: 'Exported patient & appointment records from Dr. Patil\'s Centre of Advance Dentistry.',
    );

    return filePath;
  }

  /// Backup Database Export: shares the actual SQLite database file
  static Future<String> exportDatabaseBackup() async {
    final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
    final dbFile = File(dbPath);

    if (!await dbFile.exists()) {
      throw Exception('Database file not found on device.');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final backupFileName = 'dr_patil_backup_$timestamp.db';
    final backupFilePath = p.join(tempDir.path, backupFileName);

    await dbFile.copy(backupFilePath);

    await Share.shareXFiles(
      [XFile(backupFilePath, mimeType: 'application/x-sqlite3', name: backupFileName)],
      subject: 'Dr. Patil Clinic DB Backup ($timestamp)',
      text: 'Encrypted local SQLite backup of Dr. Patil\'s Centre of Advance Dentistry.',
    );

    return backupFilePath;
  }
}
