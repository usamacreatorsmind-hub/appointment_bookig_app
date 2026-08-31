import 'package:cloud_firestore/cloud_firestore.dart';

class PatientProfileModel {
  final String? profilePhoto;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final List<String> medicalHistory;
  final List<String> currentMedications;
  final List<String> allergies;
  final String? emergencyContactName;
  final String? emergencyContactNumber;
  final String? emergencyContactRelation;
  final String? guardianName; // Added for Critical Patient Info
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final bool isProfileComplete;
  final DateTime? updatedAt;

  const PatientProfileModel({
    this.profilePhoto,
    this.dob,
    this.gender,
    this.bloodGroup,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.medicalHistory = const [],
    this.currentMedications = const [],
    this.allergies = const [],
    this.emergencyContactName,
    this.emergencyContactNumber,
    this.emergencyContactRelation,
    this.guardianName,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.isProfileComplete = false,
    this.updatedAt,
  });

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _parseDateToString(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      final date = value.toDate();
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }
    return value.toString();
  }

  factory PatientProfileModel.fromMap(Map<String, dynamic> map) {
    return PatientProfileModel(
      profilePhoto: map['profilePhoto'] ?? map['profilePhotoUrl'],
      dob: _parseDateToString(map['dob']),
      gender: map['gender']?.toString(),
      bloodGroup: map['bloodGroup'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      pincode: map['pincode'],
      medicalHistory: List<String>.from(map['medicalHistory'] ?? []),
      currentMedications: List<String>.from(map['currentMedications'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      emergencyContactName: map['emergencyContactName'],
      emergencyContactNumber: map['emergencyContactNumber'],
      emergencyContactRelation: map['emergencyContactRelation'],
      guardianName: map['guardianName'],
      insuranceProvider: map['insuranceProvider'] ?? map['insuranceDetails']?['provider'],
      insurancePolicyNumber: map['insurancePolicyNumber'] ?? map['insuranceDetails']?['policyNo'],
      isProfileComplete: map['isProfileComplete'] ?? true,
      updatedAt: _parseDateTimeNullable(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profilePhoto': profilePhoto,
      'dob': dob,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'medicalHistory': medicalHistory,
      'currentMedications': currentMedications,
      'allergies': allergies,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'emergencyContactRelation': emergencyContactRelation,
      'guardianName': guardianName,
      'insuranceProvider': insuranceProvider,
      'insurancePolicyNumber': insurancePolicyNumber,
      'isProfileComplete': isProfileComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
