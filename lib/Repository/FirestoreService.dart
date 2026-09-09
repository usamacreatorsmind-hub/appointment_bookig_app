import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/hospital_model.dart';
import '../models/doctor_model.dart';
import '../models/doctor_schedule_model.dart';
import '../models/appointment_model.dart';
import '../models/payment_model.dart';
import '../models/prescription_model.dart';
import '../models/review_model.dart';
import '../models/notification_model.dart';
import '../models/patient_profile_model.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _db = FirebaseFirestore.instance;

  // ── Collection References ──
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _hospitals => _db.collection('hospitals');
  CollectionReference get _doctors => _db.collection('doctors');
  CollectionReference get _patientsLegacy => _db.collection('patients');
  CollectionReference get _schedules => _db.collection('doctor_schedules');
  CollectionReference get _appointments => _db.collection('appointments');
  CollectionReference get _payments => _db.collection('payments');
  CollectionReference get _prescriptions => _db.collection('prescriptions');
  CollectionReference get _reviews => _db.collection('reviews');
  CollectionReference get _notifications => _db.collection('notifications');
  CollectionReference get _symptomsMaster => _db.collection('symptoms_master');
  CollectionReference get _diseaseMaster => _db.collection('disease_master');
  CollectionReference get _specializationMaster => _db.collection('specialization_master');
  CollectionReference get _qualificationMaster => _db.collection('qualification_master');
  CollectionReference get _joinRequests => _db.collection('doctor_hospital_requests');

  // ════════════════════════════════════════
  // USERS & PROFILE
  // ════════════════════════════════════════

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final snap = await _users.where('email', isEqualTo: email).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromMap(snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  Future<UserModel?> getUserByMobile(String mobile) async {
    final snap = await _users.where('mobile', isEqualTo: mobile).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromMap(snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  Future<void> migrateUserToUid(String oldId, UserModel user) async {
    if (oldId != user.uid) {
      final batch = _db.batch();
      batch.delete(_users.doc(oldId));
      batch.set(_users.doc(user.uid), user.toMap());
      await batch.commit();
    } else {
      await _users.doc(user.uid).set(user.toMap());
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _users.doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }

  Future<void> savePatientProfile(String uid, PatientProfileModel profile) async {
    await _users.doc(uid).collection('profile').doc('details').set(profile.toMap());
  }

  Future<PatientProfileModel?> getPatientProfile(String uid) async {
    // 1. Try modern location: users/{uid}/profile/details
    final doc = await _users.doc(uid).collection('profile').doc('details').get();
    if (doc.exists) {
      return PatientProfileModel.fromMap(doc.data() as Map<String, dynamic>);
    }

    // 2. Fallback to legacy location: patients collection where userId == uid
    final legacySnap = await _patientsLegacy.where('userId', isEqualTo: uid).limit(1).get();
    if (legacySnap.docs.isNotEmpty) {
      return PatientProfileModel.fromMap(legacySnap.docs.first.data() as Map<String, dynamic>);
    }

    // 3. Last fallback: patients collection where docId == uid (if seeded without userId)
    final legacyDoc = await _patientsLegacy.doc(uid).get();
    if (legacyDoc.exists) {
      return PatientProfileModel.fromMap(legacyDoc.data() as Map<String, dynamic>);
    }

    return null;
  }

  // ════════════════════════════════════════
  // HOSPITALS & DOCTORS
  // ════════════════════════════════════════

  Future<String> createHospital(HospitalModel hospital) async {
    final doc = await _hospitals.add(hospital.toMap());
    return doc.id;
  }

  Future<HospitalModel?> getHospital(String hospitalId) async {
    final doc = await _hospitals.doc(hospitalId).get();
    if (!doc.exists) return null;
    return HospitalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<List<HospitalModel>> getAllHospitals() async {
    try {
      // Robust fetching: try 'active', then 'Active', then all fallback
      var snap = await _hospitals.where('status', isEqualTo: 'active').get();
      if (snap.docs.isEmpty) {
        snap = await _hospitals.where('status', isEqualTo: 'Active').get();
      }
      if (snap.docs.isEmpty) {
        snap = await _hospitals.get();
      }

      print("🏥 Total hospital docs fetched: ${snap.docs.length}");

      return snap.docs
          .map((d) {
            try {
              return HospitalModel.fromMap(d.data() as Map<String, dynamic>, d.id);
            } catch (e) {
              print("❌ Parse error Hospital ${d.id}: $e");
              return null;
            }
          })
          .whereType<HospitalModel>()
          .toList();
    } catch (e) {
      print("Firestore Error (getAllHospitals): $e");
      try {
        final allSnap = await _hospitals.get();
        return allSnap.docs.map((d) => HospitalModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
      } catch (_) {
        return [];
      }
    }
  }

  Future<String> createDoctor(DoctorModel doctor) async {
    final doc = await _doctors.add(doctor.toMap());
    return doc.id;
  }

  Future<DoctorModel?> getDoctor(String doctorId) async {
    final doc = await _doctors.doc(doctorId).get();
    if (!doc.exists) return null;
    return DoctorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<DoctorModel?> getDoctorByUid(String uid) async {
    // Try searching by 'uid' first
    var snap = await _doctors.where('uid', isEqualTo: uid).limit(1).get();

    // If not found, try searching by 'userId' (Legacy or mismatch support)
    if (snap.docs.isEmpty) {
      snap = await _doctors.where('userId', isEqualTo: uid).limit(1).get();
    }

    if (snap.docs.isEmpty) return null;
    return DoctorModel.fromMap(snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  Future<List<DoctorModel>> getDoctorsByHospital(String hospitalId) async {
    final snap = await _doctors.where('hospitalIds', arrayContains: hospitalId).where('status', isEqualTo: 'active').get();
    return snap.docs.map((d) => DoctorModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
  }

  // ════════════════════════════════════════
  // JOIN REQUESTS (Doctor <-> Hospital)
  // ════════════════════════════════════════

  Future<void> createJoinRequest(Map<String, dynamic> requestData) async {
    await _joinRequests.add({...requestData, 'status': 'pending', 'createdAt': FieldValue.serverTimestamp()});
  }

  /// PAGINATED SEARCH: Uses limit and startAfter for efficient data fetching.
  Future<Map<String, dynamic>> searchDoctorsPaginated({
    String? sector,
    String? specialization,
    String? name,
    double? maxFee,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _doctors.where('status', isEqualTo: 'active');

      if (sector != null && sector.isNotEmpty) {
        query = query.where('sector', isEqualTo: sector);
      }

      if (specialization != null && specialization.isNotEmpty) {
        query = query.where('specialization', arrayContains: specialization);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snap = await query.limit(limit).get();

      List<DoctorModel> results = snap.docs.map((d) => DoctorModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

      // Secondary in-memory filtering
      if (maxFee != null) {
        results = results.where((d) => d.consultationFee <= maxFee).toList();
      }

      if (name != null && name.isNotEmpty) {
        final term = name.toLowerCase();
        results = results.where((d) {
          final nameMatch = d.doctorName.toLowerCase().contains(term);
          final specMatch = d.specialization.any((s) => s.toLowerCase().contains(term));
          final symMatch = d.symptomsCovered.any((s) => s.toLowerCase().contains(term));
          final disMatch = d.diseasesCovered.any((dis) => dis.toLowerCase().contains(term));
          final clinicMatch = d.clinicName?.toLowerCase().contains(term) ?? false;

          return nameMatch || specMatch || symMatch || disMatch || clinicMatch;
        }).toList();
      }

      return {'docs': results, 'lastDoc': snap.docs.isNotEmpty ? snap.docs.last : null, 'hasMore': snap.docs.length == limit};
    } catch (e) {
      print("Firestore Paginated Search Error: $e");
      return {'docs': [], 'lastDoc': null, 'hasMore': false};
    }
  }

  Future<List<DoctorModel>> getTopDoctors({String? sector, int limit = 10}) async {
    try {
      Query query = _doctors.where('status', whereIn: ['active', 'Active']);
      if (sector != null) {
        query = query.where('sector', isEqualTo: sector);
      }
      final snap = await query.get();
      List<DoctorModel> list = snap.docs.map((d) => DoctorModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
      list.sort((a, b) => (b.rating).compareTo(a.rating));
      return list.take(limit).toList();
    } catch (e) {
      print("Firestore Error (getTopDoctors): $e");
      return [];
    }
  }

  Future<void> updateDoctor(String doctorId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();

    // Robust check: If doctorId is empty, try to find by uid first
    if (doctorId.isEmpty && data['uid'] != null) {
      final snap = await _doctors.where('uid', isEqualTo: data['uid']).limit(1).get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update(data);
        return;
      } else {
        // If not found at all, create it
        await _doctors.add(data);
        return;
      }
    }

    if (doctorId.isNotEmpty) {
      await _doctors.doc(doctorId).update(data);
    } else {
      throw Exception("Doctor ID and UID both missing. Cannot update profile.");
    }
  }

  // Master Data Methods with robust extraction fallback
  Future<List<String>> getSymptoms() async {
    try {
      final snap = await _symptomsMaster.get();
      if (snap.docs.isEmpty) {
        // Fallback: try extracting symptoms from doctors collection
        final doctorsSnap = await _doctors.get();
        final symptoms = <String>{};
        for (var doc in doctorsSnap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final s = data?['symptomsCovered'];
          if (s is List) {
            symptoms.addAll(s.map((e) => e.toString()).where((e) => e.isNotEmpty));
          }
        }
        return symptoms.toList()..sort();
      }
      return snap.docs.map((d) => (d.data() as Map<String, dynamic>?)?['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        ..sort();
    } catch (e) {
      print("Firestore Error (getSymptoms): $e");
      return [];
    }
  }

  Future<List<String>> getDiseases() async {
    try {
      final snap = await _diseaseMaster.get();
      if (snap.docs.isEmpty) {
        // Fallback: try extracting diseases from doctors collection
        final doctorsSnap = await _doctors.get();
        final diseases = <String>{};
        for (var doc in doctorsSnap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final d = data?['diseasesCovered'];
          if (d is List) {
            diseases.addAll(d.map((e) => e.toString()).where((e) => e.isNotEmpty));
          }
        }
        return diseases.toList()..sort();
      }
      return snap.docs.map((d) => (d.data() as Map<String, dynamic>?)?['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        ..sort();
    } catch (e) {
      print("Firestore Error (getDiseases): $e");
      return [];
    }
  }

  Future<List<String>> getSpecializations() async {
    try {
      var snap = await _specializationMaster.where('status', isEqualTo: 'active').get();
      if (snap.docs.isEmpty) {
        snap = await _specializationMaster.get();
      }

      if (snap.docs.isEmpty) {
        // Fallback to extraction from doctors if master is empty
        final doctorsSnap = await _doctors.get();
        final specs = <String>{};
        for (var doc in doctorsSnap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final spec = data['specialization'];
          if (spec is List) {
            specs.addAll(spec.map((e) => e.toString()).where((e) => e.isNotEmpty));
          } else if (spec is String && spec.isNotEmpty) {
            specs.add(spec);
          }
        }
        return specs.toList()..sort();
      }

      return snap.docs.map((d) => (d.data() as Map<String, dynamic>?)?['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        ..sort();
    } catch (e) {
      print("Firestore Error (getSpecializations): $e");
      return [];
    }
  }

  Future<List<String>> getUsedSpecializations({String? sector}) async {
    try {
      Query query = _doctors.where('status', isEqualTo: 'active');
      if (sector != null) {
        query = query.where('sector', isEqualTo: sector);
      }
      final doctorsSnap = await query.get();
      final specs = <String>{};
      for (var doc in doctorsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final spec = data['specialization'];
        if (spec is List) {
          specs.addAll(spec.map((e) => e.toString()).where((e) => e.isNotEmpty));
        } else if (spec is String && spec.isNotEmpty) {
          specs.add(spec);
        }
      }
      return specs.toList()..sort();
    } catch (e) {
      print("Firestore Error (getUsedSpecializations): $e");
      return [];
    }
  }

  Future<List<String>> getQualifications() async {
    try {
      var snap = await _qualificationMaster.where('status', isEqualTo: 'active').get();
      if (snap.docs.isEmpty) {
        snap = await _qualificationMaster.get();
      }

      if (snap.docs.isEmpty) {
        // Fallback: try extracting from doctors
        final doctorsSnap = await _doctors.get();
        final quals = <String>{};
        for (var doc in doctorsSnap.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final q = data['qualification'];
          if (q is List) {
            quals.addAll(q.map((e) => e.toString()).where((e) => e.isNotEmpty));
          } else if (q is String && q.isNotEmpty) {
            quals.addAll(q.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
          }
        }
        return quals.toList()..sort();
      }

      return snap.docs.map((d) => (d.data() as Map<String, dynamic>?)?['name']?.toString() ?? '').where((s) => s.isNotEmpty).toList()
        ..sort();
    } catch (e) {
      print("Firestore Error (getQualifications): $e");
      return [];
    }
  }

  // ════════════════════════════════════════
  // SCHEDULES & APPOINTMENTS
  // ════════════════════════════════════════

  Future<String> createSchedule(DoctorScheduleModel schedule) async {
    final doc = await _schedules.add(schedule.toMap());
    return doc.id;
  }

  Future<List<DoctorScheduleModel>> getDoctorSchedules(String doctorId) async {
    final snap = await _schedules.where('doctorId', isEqualTo: doctorId).where('availabilityStatus', isEqualTo: 'available').get();
    return snap.docs.map((doc) => DoctorScheduleModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> updateSchedule(String scheduleId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _schedules.doc(scheduleId).update(data);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _schedules.doc(scheduleId).delete();
  }

  Future<String> createAppointment(AppointmentModel appt) async {
    final doc = await _appointments.add(appt.toMap());
    return doc.id;
  }

  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    final doc = await _appointments.doc(appointmentId).get();
    if (!doc.exists) return null;
    return AppointmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _appointments.doc(appointmentId).update(data);
  }

  Future<List<AppointmentModel>> getPatientAppointments(String patientId) async {
    try {
      final snap = await _appointments.where('patientId', isEqualTo: patientId).get();
      final list = snap.docs.map((d) => AppointmentModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      print("Error in getPatientAppointments: $e");
      return [];
    }
  }

  Future<List<AppointmentModel>> getDoctorAppointments(String doctorId, {String? date}) async {
    try {
      final snap = await _appointments.where('doctorId', isEqualTo: doctorId).get();
      var list = snap.docs.map((d) => AppointmentModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
      if (date != null && date.isNotEmpty) {
        list = list.where((a) => a.appointmentDate == date).toList();
      }
      list.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
      return list;
    } catch (e) {
      print("Error in getDoctorAppointments: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getDoctorAppointmentsPaginated(
    String doctorId, {
    String? date,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _appointments.where('doctorId', isEqualTo: doctorId);
      if (date != null && date.isNotEmpty) {
        query = query.where('appointmentDate', isEqualTo: date);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snap = await query.limit(limit).get();
      final results = snap.docs.map((d) => AppointmentModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

      return {'docs': results, 'lastDoc': snap.docs.isNotEmpty ? snap.docs.last : null, 'hasMore': snap.docs.length == limit};
    } catch (e) {
      print("Error in getDoctorAppointmentsPaginated: $e");
      return {'docs': [], 'lastDoc': null, 'hasMore': false};
    }
  }

  Future<List<String>> getBookedSlots(String doctorId, String date) async {
    try {
      final snap = await _appointments.where('doctorId', isEqualTo: doctorId).where('appointmentDate', isEqualTo: date).get();
      return snap.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .where((data) => data['status'] != 'Cancelled')
          .map((data) => data['timeSlot'] as String)
          .toList();
    } catch (e) {
      print("Error in getBookedSlots: $e");
      return [];
    }
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await _appointments.doc(appointmentId).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
  }

  /// STREAM: Listen to real-time appointment updates for a doctor on a specific date.
  Stream<List<AppointmentModel>> getDoctorAppointmentsStream(String doctorId, String date) {
    return _appointments
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((d) => AppointmentModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    });
  }

  // ════════════════════════════════════════
  // PRESCRIPTIONS
  // ════════════════════════════════════════

  Future<String> createPrescription(PrescriptionModel prescription) async {
    final doc = await _prescriptions.add(prescription.toMap());
    return doc.id;
  }

  Future<List<PrescriptionModel>> getPatientPrescriptions(String patientId) async {
    final snap = await _prescriptions.where('patientId', isEqualTo: patientId).get();
    return snap.docs.map((doc) => PrescriptionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<PrescriptionModel?> getPrescriptionByAppointment(String appointmentId) async {
    final snap = await _prescriptions.where('appointmentId', isEqualTo: appointmentId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return PrescriptionModel.fromMap(snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  // ════════════════════════════════════════
  // PAYMENTS
  // ════════════════════════════════════════

  Future<String> createPayment(PaymentModel payment) async {
    final doc = await _payments.add(payment.toMap());
    return doc.id;
  }

  // ════════════════════════════════════════
  // REVIEWS & RATINGS
  // ════════════════════════════════════════

  Future<void> submitReview(ReviewModel review) async {
    final batch = _db.batch();

    // 1. Add review document
    final reviewRef = _reviews.doc();
    batch.set(reviewRef, review.toMap());

    // 2. Get current doctor data to update rating
    final doctorDoc = await _doctors.doc(review.doctorId).get();
    if (doctorDoc.exists) {
      final data = doctorDoc.data() as Map<String, dynamic>;
      final double currentRating = (data['rating'] ?? 0.0).toDouble();
      final int totalReviews = (data['totalReviews'] ?? 0).toInt();

      // Calculate new average rating
      final double newRating = ((currentRating * totalReviews) + review.rating) / (totalReviews + 1);

      batch.update(_doctors.doc(review.doctorId), {
        'rating': double.parse(newRating.toStringAsFixed(1)),
        'totalReviews': totalReviews + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Mark appointment as reviewed (optional but good practice)
    batch.update(_appointments.doc(review.appointmentId), {'isReviewed': true});

    await batch.commit();
  }

  Future<List<ReviewModel>> getDoctorReviews(String doctorId) async {
    final snap = await _reviews.where('doctorId', isEqualTo: doctorId).get();
    final list = snap.docs.map((d) => ReviewModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<bool> hasPatientReviewed(String appointmentId) async {
    final snap = await _reviews.where('appointmentId', isEqualTo: appointmentId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  // ════════════════════════════════════════
  // NOTIFICATIONS
  // ════════════════════════════════════════

  Future<void> createNotification(NotificationModel notification) async {
    await _notifications.add(notification.toMap());
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notifications.where('userId', isEqualTo: userId).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final unreadSnap = await _notifications.where('userId', isEqualTo: userId).where('isRead', isEqualTo: false).get();

    if (unreadSnap.docs.isEmpty) return;

    final batch = _db.batch();
    for (var doc in unreadSnap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
