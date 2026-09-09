
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appointment_booking_app/Repository/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../models/doctor_model.dart';
import '../../../models/appointment_model.dart';
import '../../../models/notification_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_routes.dart';
import '../../../utils/helper.dart';
import '../../role_selection/role_selection_controller.dart';

class DoctorDashboardController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  FirestoreService get firestoreService => _firestoreService;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthRepository _authRepository = AuthRepository();

  final scrollController = ScrollController();
  StreamSubscription? _appointmentsSubscription;

  final isLoading = false.obs;
  final isAppointmentsLoading = false.obs;
  final isLoadMore = false.obs;
  final currentIndex = 0.obs;

  final doctorProfile = Rxn<DoctorModel>();
  final appointments = <AppointmentModel>[].obs;
  final allPatients = <UserModel>[].obs;
  final filteredPatients = <UserModel>[].obs;
  final isPatientsLoading = false.obs;
  final patientSearchQuery = "".obs;

  // New Home Tab States
  final isOnline = true.obs;
  final nextAppointment = Rxn<AppointmentModel>();

  // Stats
  final confirmedTodayCount = 0.obs;
  final pendingTodayCount = 0.obs;
  final totalTodayCount = 0.obs;

  // Pagination
  DocumentSnapshot? lastDocument;
  final hasMore = true.obs;
  final int limit = 10;

  // Reactive selected date string
  final selectedDate = "".obs;

  // Stable list of dates for the selector (Next 14 days)
  final dateList = <DateTime>[].obs;

  @override
  void onInit() {
    super.onInit();
    _generateDates();
    selectedDate.value = DateFormat('yyyy-MM-dd').format(DateTime.now());

    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        loadMoreAppointments();
      }
    });

    loadDashboardData();
  }

  void _generateDates() {
    final now = DateTime.now();
    dateList.assignAll(List.generate(14, (i) => now.add(Duration(days: i))));
  }

  Future<void> loadDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    update();

    try {
      final profile = await _firestoreService.getDoctorByUid(user.uid);
      if (profile != null) {
        doctorProfile.value = profile;

        // Robust Hospital ID Fallback
        if (doctorProfile.value!.hospitalId.isEmpty) {
          final userModel = await _firestoreService.getUser(user.uid);
          if (userModel?.hospitalId != null && userModel!.hospitalId!.isNotEmpty) {
            doctorProfile.value = doctorProfile.value!.copyWith(hospitalId: userModel.hospitalId);
          }
        }

        await loadAppointments(selectedDate.value);
      } else {
        AppSnackBar.show('Doctor profile not found in database.');
      }
    } catch (e) {
      AppSnackBar.show('Failed to load dashboard: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> loadAppointments(String date) async {
    selectedDate.value = date;

    if (doctorProfile.value == null) return;

    isAppointmentsLoading.value = true;
    update();

    // Cancel previous subscription if any
    await _appointmentsSubscription?.cancel();

    // Listen to real-time updates
    _appointmentsSubscription = _firestoreService
        .getDoctorAppointmentsStream(doctorProfile.value!.doctorId, date)
        .listen((results) async {
      List<AppointmentModel> enhancedAppts = [];
      for (var appt in results) {
        // Hide 'Pending' appointments from the doctor until payment is confirmed
        if (appt.status.toLowerCase() == 'pending') continue;
        enhancedAppts.add(await _enhanceAppointment(appt));
      }

      // Sort: Arrived first, then by token number, then by time
      enhancedAppts.sort((a, b) {
        if (a.status == 'Arrived' && b.status != 'Arrived') return -1;
        if (a.status != 'Arrived' && b.status == 'Arrived') return 1;

        if (a.tokenNumber != null && b.tokenNumber != null) {
          return a.tokenNumber!.compareTo(b.tokenNumber!);
        }
        return a.timeSlot.compareTo(b.timeSlot);
      });

      appointments.assignAll(enhancedAppts);
      _updateStats();
      isAppointmentsLoading.value = false;
      update();
    }, onError: (e) {
      isAppointmentsLoading.value = false;
      AppSnackBar.show('Failed to listen to appointments: $e');
      update();
    });
  }

  Future<void> loadMoreAppointments() async {
    if (isLoadMore.value || !hasMore.value || doctorProfile.value == null) return;

    isLoadMore.value = true;
    update();

    try {
      final result = await _firestoreService.getDoctorAppointmentsPaginated(
        doctorProfile.value!.doctorId,
        date: selectedDate.value,
        lastDocument: lastDocument,
        limit: limit,
      );

      final results = result['docs'] as List<AppointmentModel>;
      lastDocument = result['lastDoc'] as DocumentSnapshot?;
      hasMore.value = result['hasMore'] as bool;

      List<AppointmentModel> enhancedAppts = [];
      for (var appt in results) {
        // Hide 'Pending' appointments from the doctor until payment is confirmed
        if (appt.status.toLowerCase() == 'pending') continue;
        enhancedAppts.add(await _enhanceAppointment(appt));
      }

      appointments.addAll(enhancedAppts);
      // Re-sort entire list
      appointments.sort((a, b) {
        if (a.status == 'Arrived' && b.status != 'Arrived') return -1;
        if (a.status != 'Arrived' && b.status == 'Arrived') return 1;
        if (a.tokenNumber != null && b.tokenNumber != null) return a.tokenNumber!.compareTo(b.tokenNumber!);
        return a.timeSlot.compareTo(b.timeSlot);
      });
    } catch (e) {
      print("Error loading more appointments: $e");
    } finally {
      isLoadMore.value = false;
      update();
    }
  }

  Future<AppointmentModel> _enhanceAppointment(AppointmentModel appt) async {
    try {
      final patientData = await _firestoreService.getUser(appt.patientId);
      String patientName = patientData?.name ?? 'Patient';
      Map<String, dynamic>? details = appt.patientDetails;

      if (appt.isForSelf) {
        final profile = await _firestoreService.getPatientProfile(appt.patientId);
        if (profile != null) {
          details = {
            'name': patientName,
            'age': _calculateAge(profile.dob),
            'gender': profile.gender ?? 'N/A',
            'address': profile.address ?? 'N/A',
            'relationship': 'Self',
          };
        }
      } else if (appt.patientDetails != null && appt.patientDetails!['name'] != null) {
        patientName = appt.patientDetails!['name'];
      }

      return appt.copyWith(patientName: patientName, patientDetails: details);
    } catch (e) {
      return appt.copyWith(patientName: 'Patient');
    }
  }

  String _calculateAge(String? dobStr) {
    if (dobStr == null || dobStr.isEmpty) return "N/A";
    try {
      DateTime? dob;
      if (dobStr.contains('/')) {
        List<String> parts = dobStr.split('/');
        if (parts.length == 3) {
          dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } else {
        dob = DateTime.tryParse(dobStr);
      }

      if (dob != null) {
        final now = DateTime.now();
        int age = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
        return "$age Years";
      }
    } catch (e) {
      debugPrint("Age calculation error: $e");
    }
    return "N/A";
  }

  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firestoreService.updateAppointmentStatus(appointmentId, status);

      final appt = appointments.firstWhereOrNull((a) => a.appointmentId == appointmentId);
      if (appt != null) {
        await _firestoreService.createNotification(
          NotificationModel(
            notificationId: '',
            userId: appt.patientId,
            title: 'Appointment $status',
            message: 'Your appointment on ${appt.appointmentDate} has been $status by Dr. ${doctorProfile.value?.doctorName}',
            type: 'appointment',
            channel: 'app',
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );
      }

      await loadAppointments(selectedDate.value);
      AppSnackBar.show('Appointment $status');
    } catch (e) {
      AppSnackBar.show('Failed to update status: $e');
    }
  }

  void _updateStats() {
    totalTodayCount.value = appointments.length;
    confirmedTodayCount.value = appointments.where((a) => a.status == 'Confirmed').length;
    pendingTodayCount.value = appointments.where((a) => a.status == 'Pending').length;

    // Find next appointment for Home Tab
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (selectedDate.value == today) {
      nextAppointment.value = appointments.firstWhereOrNull((a) => a.status == 'Confirmed' || a.status == 'Arrived');
    } else {
      nextAppointment.value = null;
    }
  }

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 2) {
      loadAllPatients();
    }
  }

  Future<void> loadAllPatients() async {
    if (doctorProfile.value == null) return;
    isPatientsLoading.value = true;
    update();
    try {
      final allAppts = await _firestoreService.getDoctorAppointments(doctorProfile.value!.doctorId);
      final patientIds = allAppts.map((a) => a.patientId).toSet().toList();

      List<UserModel> patients = [];
      for (String pid in patientIds) {
        final p = await _firestoreService.getUser(pid);
        if (p != null) patients.add(p);
      }

      allPatients.assignAll(patients);
      filteredPatients.assignAll(patients);
    } catch (e) {
      print("Error loading patients: $e");
    } finally {
      isPatientsLoading.value = false;
      update();
    }
  }

  void onPatientSearch(String query) {
    patientSearchQuery.value = query;
    if (query.isEmpty) {
      filteredPatients.assignAll(allPatients);
    } else {
      filteredPatients.assignAll(allPatients.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList());
    }
  }

  Future<void> onRefresh() async {
    if (currentIndex.value == 0 || currentIndex.value == 1) await loadDashboardData();
    if (currentIndex.value == 2) await loadAllPatients();
  }

  Future<void> logout() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _authRepository.signOut();
              Get.offAllNamed(AppRoutes.roleSelection);
              Get.toNamed(AppRoutes.login, arguments: {'role': UserRole.doctor});
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    _appointmentsSubscription?.cancel();
    scrollController.dispose();
    super.onClose();
  }
}
