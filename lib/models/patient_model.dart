import 'package:intl/intl.dart';
import 'appointment_model.dart';

/// Minimal patient view strictly for Receptionists (Data-access layer privacy guarantee)
/// Never exposes age, address, phone numbers, problems, or payment history to receptionist view.
class MinimalPatient {
  final int id;
  final String name;
  final DateTime registrationDate;
  final bool isEligibleForGraceEdit;

  MinimalPatient({
    required this.id,
    required this.name,
    required this.registrationDate,
    this.isEligibleForGraceEdit = false,
  });

  factory MinimalPatient.fromMap(Map<String, dynamic> map, {bool isEligibleForGraceEdit = false}) {
    return MinimalPatient(
      id: map['id'] as int,
      name: map['name'] as String,
      registrationDate: DateTime.parse(map['registration_date'] as String),
      isEligibleForGraceEdit: isEligibleForGraceEdit,
    );
  }
}

/// Full Patient Model for Admin View, Database Persistence & CSV Export
class Patient {
  final int? id;               // auto-increment (Sr. No)
  final String name;
  final int age;
  final String sex;            // 'Male' | 'Female' | 'Other'
  final bool firstTime;        // true = First Time, false = Already Consulted
  final DateTime? lastConsultationDate;
  final String? problem;
  final String? photoPath;     // local file path
  final String phone1;
  final String phone2;
  final String address;
  final DateTime registrationDate;
  final String paymentStatus;  // 'Pending' or 'Paid'
  final bool isDeleted;        // soft-delete flag
  final List<Appointment> appointments;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.sex,
    required this.firstTime,
    this.lastConsultationDate,
    this.problem,
    this.photoPath,
    required this.phone1,
    required this.phone2,
    required this.address,
    required this.registrationDate,
    this.paymentStatus = 'Pending',
    this.isDeleted = false,
    this.appointments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'sex': sex,
      'first_time': firstTime ? 1 : 0,
      'last_consultation_date': lastConsultationDate?.toIso8601String(),
      'problem': problem,
      'photo_path': photoPath,
      'phone1': phone1,
      'phone2': phone2,
      'address': address,
      'registration_date': registrationDate.toIso8601String(),
      'payment_status': paymentStatus,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map, {List<Appointment> appointments = const []}) {
    return Patient(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int,
      sex: map['sex'] as String,
      firstTime: (map['first_time'] as int) == 1,
      lastConsultationDate: map['last_consultation_date'] != null
          ? DateTime.parse(map['last_consultation_date'] as String)
          : null,
      problem: map['problem'] as String?,
      photoPath: map['photo_path'] as String?,
      phone1: map['phone1'] as String,
      phone2: map['phone2'] as String,
      address: map['address'] as String,
      registrationDate: DateTime.parse(map['registration_date'] as String),
      paymentStatus: map['payment_status'] as String? ?? 'Pending',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      appointments: appointments,
    );
  }

  String get formattedRegDate => DateFormat('MMM dd, yyyy').format(registrationDate);
  String get formattedLastConsultation => lastConsultationDate != null
      ? DateFormat('MMM dd, yyyy').format(lastConsultationDate!)
      : 'N/A';

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? sex,
    bool? firstTime,
    DateTime? lastConsultationDate,
    String? problem,
    String? photoPath,
    String? phone1,
    String? phone2,
    String? address,
    DateTime? registrationDate,
    String? paymentStatus,
    bool? isDeleted,
    List<Appointment>? appointments,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      firstTime: firstTime ?? this.firstTime,
      lastConsultationDate: lastConsultationDate ?? this.lastConsultationDate,
      problem: problem ?? this.problem,
      photoPath: photoPath ?? this.photoPath,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      address: address ?? this.address,
      registrationDate: registrationDate ?? this.registrationDate,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      appointments: appointments ?? this.appointments,
    );
  }
}
