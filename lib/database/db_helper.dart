import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/patient_model.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dr_patil_dentistry.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table (with salted password hashes)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        role TEXT NOT NULL,
        name TEXT NOT NULL
      )
    ''');

    // 2. Patients Table (with soft-delete flag)
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        sex TEXT NOT NULL,
        first_time INTEGER NOT NULL DEFAULT 1,
        last_consultation_date TEXT,
        problem TEXT,
        photo_path TEXT,
        phone1 TEXT NOT NULL,
        phone2 TEXT NOT NULL,
        address TEXT NOT NULL,
        registration_date TEXT NOT NULL,
        payment_status TEXT NOT NULL DEFAULT 'Pending',
        is_deleted INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 3. Appointments Table
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        date_time TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (patient_id) REFERENCES patients (id) ON DELETE CASCADE
      )
    ''');

    // Seed default credentials with secure salted hashes
    await _seedDefaultUsers(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Schema migration strategy for future field additions without wiping data
    if (oldVersion < 2) {
      // Future migration example:
      // await db.execute('ALTER TABLE patients ADD COLUMN email TEXT');
    }
  }

  // Seed pre-registered accounts
  Future<void> _seedDefaultUsers(Database db) async {
    final usersToSeed = [
      {
        'email': 'admin@drpatil.com',
        'password': 'Admin@123',
        'role': 'admin',
        'name': 'Dr. Patil (Admin)',
      },
      {
        'email': 'reception1@drpatil.com',
        'password': 'Reception@123',
        'role': 'receptionist',
        'name': 'Front Desk Desk 1',
      },
      {
        'email': 'reception2@drpatil.com',
        'password': 'Reception@123',
        'role': 'receptionist',
        'name': 'Front Desk Desk 2',
      },
    ];

    for (var u in usersToSeed) {
      final salt = _generateSalt();
      final hash = _hashPassword(u['password']!, salt);

      await db.insert('users', {
        'email': u['email'],
        'password_hash': hash,
        'salt': salt,
        'role': u['role'],
        'name': u['name'],
      });
    }
  }

  static String _generateSalt([int length = 32]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // -------------------------------------------------------------
  // AUTH QUERIES
  // -------------------------------------------------------------
  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [email.trim().toLowerCase()],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  bool verifyPassword(String enteredPassword, String storedHash, String salt) {
    final computedHash = _hashPassword(enteredPassword, salt);
    return computedHash == storedHash;
  }

  // -------------------------------------------------------------
  // RECEPTIONIST DATA-LAYER ENFORCED QUERIES
  // -------------------------------------------------------------

  /// Data-layer privacy enforcement: Receptionist query NEVER selects sensitive
  /// medical / contact columns (age, phone, problem, address, payment_status).
  Future<List<MinimalPatient>> getMinimalPatientsForReception() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT id, name, registration_date 
      FROM patients 
      WHERE is_deleted = 0 
      ORDER BY id DESC
    ''');

    // Determine grace window (last 5 records registered within past 3 hours)
    final now = DateTime.now();
    return maps.asMap().entries.map((entry) {
      final index = entry.key;
      final map = entry.value;
      final regDate = DateTime.parse(map['registration_date'] as String);
      final isRecentIndex = index < 5;
      final isRecentTime = now.difference(regDate).inMinutes <= 180;
      final isGraceEligible = isRecentIndex && isRecentTime;

      return MinimalPatient.fromMap(map, isEligibleForGraceEdit: isGraceEligible);
    }).toList();
  }

  /// Grace edit allowed for receptionist (e.g. fix typo in Patient Name immediately)
  Future<bool> updatePatientNameByReception(int patientId, String newName) async {
    final db = await database;
    final count = await db.update(
      'patients',
      {'name': newName.trim()},
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [patientId],
    );
    return count > 0;
  }

  // -------------------------------------------------------------
  // PATIENT CRUD (ADMIN & GENERAL)
  // -------------------------------------------------------------

  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return await db.insert('patients', patient.toMap());
  }

  Future<List<Patient>> getAllPatients({
    String? query,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String whereClause = 'is_deleted = 0';
    List<dynamic> whereArgs = [];

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim()}%';
      whereClause += ' AND (name LIKE ? OR phone1 LIKE ? OR phone2 LIKE ? OR CAST(id AS TEXT) LIKE ?)';
      whereArgs.addAll([q, q, q, q]);
    }

    if (paymentStatus != null && paymentStatus != 'All' && paymentStatus.isNotEmpty) {
      whereClause += ' AND payment_status = ?';
      whereArgs.add(paymentStatus);
    }

    if (startDate != null) {
      whereClause += ' AND date(registration_date) >= date(?)';
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClause += ' AND date(registration_date) <= date(?)';
      whereArgs.add(endDate.toIso8601String());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'patients',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );

    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  Future<Patient?> getPatientById(int id) async {
    final db = await database;
    final patientMaps = await db.query(
      'patients',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (patientMaps.isEmpty) return null;

    final appointmentMaps = await db.query(
      'appointments',
      where: 'patient_id = ?',
      whereArgs: [id],
      orderBy: 'date_time DESC',
    );

    final appointments = appointmentMaps.map((m) => Appointment.fromMap(m)).toList();
    return Patient.fromMap(patientMaps.first, appointments: appointments);
  }

  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  Future<int> togglePaymentStatus(int patientId, String newStatus) async {
    final db = await database;
    return await db.update(
      'patients',
      {'payment_status': newStatus},
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  /// Soft Delete: Safe flag deletion preserving exports and historical appointment logs
  Future<int> softDeletePatient(int patientId) async {
    final db = await database;
    return await db.update(
      'patients',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [patientId],
    );
  }

  // -------------------------------------------------------------
  // APPOINTMENT CRUD & DOUBLE-BOOKING DETECTION
  // -------------------------------------------------------------

  Future<int> insertAppointment(Appointment appointment) async {
    final db = await database;
    return await db.insert('appointments', appointment.toMap());
  }

  Future<List<Appointment>> getAllAppointments() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.id, a.patient_id, a.date_time, a.notes, p.name AS patient_name
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      WHERE p.is_deleted = 0
      ORDER BY a.date_time ASC
    ''');

    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final db = await database;
    final dateString = date.toIso8601String().substring(0, 10); // YYYY-MM-DD
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.id, a.patient_id, a.date_time, a.notes, p.name AS patient_name
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      WHERE p.is_deleted = 0 AND date(a.date_time) = date(?)
      ORDER BY a.date_time ASC
    ''', [dateString]);

    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  /// Checks for overlapping appointments within a window (e.g. ±30 minutes)
  /// Returns conflicting appointments list if any exist.
  Future<List<Appointment>> checkAppointmentConflict(
    DateTime targetTime, {
    int? excludeAppointmentId,
    int slotDurationMinutes = 30,
  }) async {
    final db = await database;
    final startTime = targetTime.subtract(Duration(minutes: slotDurationMinutes - 1)).toIso8601String();
    final endTime = targetTime.add(Duration(minutes: slotDurationMinutes - 1)).toIso8601String();

    String query = '''
      SELECT a.id, a.patient_id, a.date_time, a.notes, p.name AS patient_name
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      WHERE p.is_deleted = 0 
        AND a.date_time >= ? 
        AND a.date_time <= ?
    ''';
    List<dynamic> args = [startTime, endTime];

    if (excludeAppointmentId != null) {
      query += ' AND a.id != ?';
      args.add(excludeAppointmentId);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return maps.map((m) => Appointment.fromMap(m)).toList();
  }

  Future<int> deleteAppointment(int appointmentId) async {
    final db = await database;
    return await db.delete(
      'appointments',
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  // -------------------------------------------------------------
  // ANALYTICS & EXPORT QUERIES
  // -------------------------------------------------------------

  Future<Map<String, int>> getDashboardAnalytics() async {
    final db = await database;

    // Total active patients
    final totalPatientsResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM patients WHERE is_deleted = 0
    ''');
    final totalPatients = Sqflite.firstIntValue(totalPatientsResult) ?? 0;

    // Pending payments
    final pendingPaymentsResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM patients WHERE is_deleted = 0 AND payment_status = 'Pending'
    ''');
    final pendingPayments = Sqflite.firstIntValue(pendingPaymentsResult) ?? 0;

    // Today's appointments
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todayAppointmentsResult = await db.rawQuery('''
      SELECT COUNT(*) as count 
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      WHERE p.is_deleted = 0 AND date(a.date_time) = date(?)
    ''', [today]);
    final todayAppointments = Sqflite.firstIntValue(todayAppointmentsResult) ?? 0;

    return {
      'totalPatients': totalPatients,
      'pendingPayments': pendingPayments,
      'todayAppointments': todayAppointments,
    };
  }

  /// Comprehensive joined query for CSV Export
  Future<List<Map<String, dynamic>>> getJoinedExportData() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        p.id AS sr_no,
        p.name AS patient_name,
        p.age,
        p.sex,
        p.first_time,
        p.last_consultation_date,
        p.problem,
        p.phone1,
        p.phone2,
        p.address,
        p.registration_date,
        p.payment_status,
        a.date_time AS appointment_date,
        a.notes AS appointment_notes
      FROM patients p
      LEFT JOIN appointments a ON p.id = a.patient_id
      WHERE p.is_deleted = 0
      ORDER BY p.id ASC, a.date_time ASC
    ''');
  }

  /// Get the actual SQLite DB file path on device
  Future<String> getDatabaseFilePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'dr_patil_dentistry.db');
  }
}
