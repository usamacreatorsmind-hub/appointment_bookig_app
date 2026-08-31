import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
// Firestore Path: appointments/{appointmentId}
// ─────────────────────────────────────────
class AppointmentModel {
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final String hospitalId;
  final String appointmentDate;
  final String timeSlot;
  final String consultationType; // Online | Offline
  final String symptoms;
  final String status; // Pending | Confirmed | Cancelled | Completed
  final String paymentStatus; // Paid | Unpaid
  final String? transactionId;
  final double fee;
  final double? bookingCharge; // Razorpay Slot Fee
  final String? notes;
  final bool isReviewed; // Added to track if review is done
  final bool isForSelf;
  final int? tokenNumber; // Serial number for the day
  final String? patientType; // New | Old
  final Map<String, dynamic>? patientDetails;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Display only (not stored in Firestore)
  final String? doctorName;
  final String? specialization;
  final String? hospitalName;
  final String? patientName;

  const AppointmentModel({
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.hospitalId,
    required this.appointmentDate,
    required this.timeSlot,
    required this.consultationType,
    required this.symptoms,
    required this.status,
    required this.paymentStatus,
    this.transactionId,
    required this.fee,
    this.bookingCharge,
    this.notes,
    this.isReviewed = false,
    this.isForSelf = true,
    this.tokenNumber,
    this.patientType,
    this.patientDetails,
    required this.createdAt,
    this.updatedAt,
    this.doctorName,
    this.specialization,
    this.hospitalName,
    this.patientName,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      appointmentId: id,
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      hospitalId: map['hospitalId'] ?? '',
      appointmentDate: map['appointmentDate'] ?? '',
      timeSlot: map['timeSlot'] ?? '',
      consultationType: map['consultationType'] ?? 'Offline',
      symptoms: map['symptoms'] ?? '',
      status: map['status'] ?? 'Pending',
      paymentStatus: map['paymentStatus'] ?? 'Unpaid',
      transactionId: map['transactionId'],
      fee: (map['fee'] ?? 0).toDouble(),
      bookingCharge: map['bookingCharge'] != null ? (map['bookingCharge']).toDouble() : null,
      notes: map['notes'],
      isReviewed: map['isReviewed'] ?? false,
      isForSelf: map['isForSelf'] ?? true,
      tokenNumber: map['tokenNumber'] != null ? int.tryParse(map['tokenNumber'].toString()) : null,
      patientType: map['patientType'],
      patientDetails: map['patientDetails'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTimeNullable(map['updatedAt']),
      doctorName: map['doctorName'],
      specialization: map['specialization'],
      hospitalName: map['hospitalName'],
      patientName: map['patientName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'hospitalId': hospitalId,
      'appointmentDate': appointmentDate,
      'timeSlot': timeSlot,
      'consultationType': consultationType,
      'symptoms': symptoms,
      'status': status,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'fee': fee,
      'bookingCharge': bookingCharge,
      'notes': notes,
      'isReviewed': isReviewed,
      'isForSelf': isForSelf,
      'tokenNumber': tokenNumber,
      'patientType': patientType,
      'patientDetails': patientDetails,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AppointmentModel copyWith({
    String? status,
    String? paymentStatus,
    String? transactionId,
    double? bookingCharge,
    String? notes,
    bool? isReviewed,
    bool? isForSelf,
    int? tokenNumber,
    String? patientType,
    Map<String, dynamic>? patientDetails,
    String? doctorName,
    String? specialization,
    String? hospitalName,
    String? patientName,
  }) {
    return AppointmentModel(
      appointmentId: appointmentId,
      patientId: patientId,
      doctorId: doctorId,
      hospitalId: hospitalId,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      consultationType: consultationType,
      symptoms: symptoms,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      fee: fee,
      bookingCharge: bookingCharge ?? this.bookingCharge,
      notes: notes ?? this.notes,
      isReviewed: isReviewed ?? this.isReviewed,
      isForSelf: isForSelf ?? this.isForSelf,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      patientType: patientType ?? this.patientType,
      patientDetails: patientDetails ?? this.patientDetails,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      doctorName: doctorName ?? this.doctorName,
      specialization: specialization ?? this.specialization,
      hospitalName: hospitalName ?? this.hospitalName,
      patientName: patientName ?? this.patientName,
    );
  }
}
