// ─────────────────────────────────────────
// Firestore Path: users/{uid}
// ─────────────────────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String mobile;
  final String email;
  final String role; // super_admin | doctor | patient | veterinary_doctor | office_staff | pet_owner | visitor
  final String status; // active | inactive
  final String? hospitalId; // doctor ke liye
  final String? doctorId; // doctor ke liye
  final String? patientId; // patient ke liye
  final String? fcmToken; // Push notification token
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.email,
    required this.role,
    required this.status,
    this.hospitalId,
    this.doctorId,
    this.patientId,
    this.fcmToken,
    required this.createdAt,
    this.updatedAt,
  });

  // ── Timestamp | String | null teeno handle karta hai ──
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

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      mobile: map['mobile'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'patient',
      status: map['status'] ?? 'active',
      hospitalId: map['hospitalId'] as String?,
      doctorId: map['doctorId'] as String?,
      patientId: map['patientId'] as String?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTimeNullable(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid, 
      'name': name,
      'mobile': mobile,
      'email': email,
      'role': role,
      'status': status,
      'hospitalId': hospitalId,
      'doctorId': doctorId,
      'patientId': patientId,
      'fcmToken': fcmToken,
      'createdAt': createdAt, 
      'updatedAt': FieldValue.serverTimestamp(), 
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? mobile,
    String? email,
    String? role,
    String? status,
    String? hospitalId,
    String? doctorId,
    String? patientId,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      hospitalId: hospitalId ?? this.hospitalId,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
