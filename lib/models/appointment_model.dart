import 'package:intl/intl.dart';

class Appointment {
  final int? id;
  final int patientId;
  final DateTime dateTime;
  final String? notes;
  final String? patientName; // Optional joined field for queue / schedule view

  Appointment({
    this.id,
    required this.patientId,
    required this.dateTime,
    this.notes,
    this.patientName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'date_time': dateTime.toIso8601String(),
      'notes': notes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as int?,
      patientId: map['patient_id'] as int,
      dateTime: DateTime.parse(map['date_time'] as String),
      notes: map['notes'] as String?,
      patientName: map['patient_name'] as String?,
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(dateTime);
  String get formattedTime => DateFormat('hh:mm a').format(dateTime);
  String get formattedDateTime => DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);

  Appointment copyWith({
    int? id,
    int? patientId,
    DateTime? dateTime,
    String? notes,
    String? patientName,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      patientName: patientName ?? this.patientName,
    );
  }
}
