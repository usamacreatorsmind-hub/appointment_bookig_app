import 'package:get/get.dart';
import '../../../Repository/auth_repository.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../models/user_model.dart';
import '../../../models/appointment_model.dart';
import '../../../utils/app_routes.dart';
import '../../role_selection/role_selection_controller.dart';
import 'package:flutter/material.dart';

class ReceptionistDashboardController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreService _firestoreService = FirestoreService();

  final Rxn<UserModel> user = Rxn<UserModel>();
  final hospitalName = 'Loading...'.obs;
  final assignedDoctorName = RxnString();
  final practiceType = 'hospital'.obs;
  final isLoading = false.obs;

  // Date management
  final selectedDate = DateTime.now().obs;
  final dateList = <DateTime>[].obs;

  // Stats & Detailed Data
  final totalPatientsCount = 0.obs;
  final confirmedCount = 0.obs;
  final pendingCount = 0.obs;
  final allAppointmentsForDate = <AppointmentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _generateDates();
    _loadUserData();
  }

  void _generateDates() {
    final now = DateTime.now();
    dateList.assignAll(List.generate(14, (i) => now.add(Duration(days: i))));
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    await _fetchStatsForDate(date);
  }

  Future<void> _loadUserData() async {
    isLoading.value = true;
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        final userData = await _authRepository.getUserData(currentUser.uid);
        user.value = userData;
        if (userData?.hospitalId != null) {
          await _fetchHospitalName(userData!.hospitalId!);
          await _fetchStatsForDate(selectedDate.value);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchHospitalName(String hId) async {
    try {
      // 1. If receptionist is assigned to a specific doctor, check for Clinic Name
      if (user.value?.doctorId != null) {
        final doctor = await _firestoreService.getDoctor(user.value!.doctorId!);
        if (doctor != null) {
          assignedDoctorName.value = doctor.doctorName;
          if (doctor.practiceType == 'clinic' && doctor.clinicName != null && doctor.clinicName!.isNotEmpty) {
            hospitalName.value = doctor.clinicName!;
            practiceType.value = 'clinic';
            return;
          }
        }
      }

      // 2. Default to Hospital Name
      practiceType.value = 'hospital';
      final h = await _firestoreService.getHospital(hId);
      if (h != null) {
        hospitalName.value = h.hospitalName;
      } else {
        hospitalName.value = 'Not Assigned';
      }
    } catch (e) {
      hospitalName.value = 'Error';
    }
  }

  Future<void> _fetchStatsForDate(DateTime date) async {
    if (user.value?.hospitalId == null) return;

    final dateStr = date.toIso8601String().split('T')[0];
    final appointments = await _firestoreService.getHospitalAppointments(user.value!.hospitalId!, date: dateStr);

    // Filter by Doctor if assigned
    final filteredAppts = user.value!.doctorId != null
        ? appointments.where((a) => a.doctorId == user.value!.doctorId).toList()
        : appointments;

    // Enhance with names for the bottom sheet
    List<AppointmentModel> enhancedList = [];
    for (var appt in filteredAppts) {
      try {
        final patientData = await _firestoreService.getUser(appt.patientId);
        final doctorData = await _firestoreService.getDoctor(appt.doctorId);
        
        String patientName = patientData?.name ?? 'Patient';
        if (!appt.isForSelf && appt.patientDetails != null && appt.patientDetails!['name'] != null) {
          patientName = appt.patientDetails!['name'];
        }
        
        enhancedList.add(appt.copyWith(
          patientName: patientName,
          doctorName: doctorData?.doctorName ?? 'Doctor',
        ));
      } catch (e) {
        enhancedList.add(appt.copyWith(patientName: 'Patient', doctorName: 'Doctor'));
      }
    }

    allAppointmentsForDate.assignAll(enhancedList);
    // Sort by token number (serial) if available, otherwise by time slot
    allAppointmentsForDate.sort((a, b) {
      if (a.tokenNumber != null && b.tokenNumber != null) {
        return a.tokenNumber!.compareTo(b.tokenNumber!);
      }
      return a.timeSlot.compareTo(b.timeSlot);
    });
    
    totalPatientsCount.value = enhancedList.length;
    confirmedCount.value = enhancedList.where((a) => 
      a.status.toLowerCase() == 'confirmed' || a.status.toLowerCase() == 'arrived' || a.status.toLowerCase() == 'completed'
    ).length;
    pendingCount.value = enhancedList.where((a) => a.status.toLowerCase() == 'pending').length;
  }

  List<AppointmentModel> getFilteredAppointments(String type) {
    switch (type) {
      case 'Total':
        return allAppointmentsForDate;
      case 'Confirmed':
        return allAppointmentsForDate.where((a) => 
          a.status.toLowerCase() == 'confirmed' || a.status.toLowerCase() == 'arrived' || a.status.toLowerCase() == 'completed'
        ).toList();
      case 'Pending':
        return allAppointmentsForDate.where((a) => a.status.toLowerCase() == 'pending').toList();
      default:
        return allAppointmentsForDate;
    }
  }

  void goToAppointments() {
    Get.toNamed(AppRoutes.receptionistAppointments, arguments: {
      'date': selectedDate.value,
    });
  }

  void signOut() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _authRepository.signOut();
              Get.offAllNamed(AppRoutes.roleSelection);
              Get.toNamed(AppRoutes.login, arguments: {'role': UserRole.receptionist});
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
