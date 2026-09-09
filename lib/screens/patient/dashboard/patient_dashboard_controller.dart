import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../models/doctor_model.dart';
import '../../../models/appointment_model.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../utils/app_routes.dart';
import '../doctor_search/doctor_search_controller.dart';

class PatientDashboardController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final isLoading = false.obs;
  final selectedIndex = 0.obs;
  final selectedSpecIndex = (-1).obs;
  final patientName = 'Patient'.obs;
  final specializations = <String>[].obs;
  final currentSector = 'human'.obs; // human | veterinary | office

  final upcomingAppointment = Rxn<AppointmentModel>();
  final topDoctors = <DoctorModel>[].obs;
  final bloodGroup = 'N/A'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    update();

    try {
      final userData = await _firestoreService.getUser(user.uid);
      if (userData != null) patientName.value = userData.name;

      final profile = await _firestoreService.getPatientProfile(user.uid);
      if (profile != null) {
        bloodGroup.value = (profile.bloodGroup != null && profile.bloodGroup!.isNotEmpty) ? profile.bloodGroup! : 'N/A';
      }

      final specs = await _firestoreService.getUsedSpecializations(sector: currentSector.value);
      if (specs.isNotEmpty) specializations.assignAll(specs);

      final doctors = await _firestoreService.getTopDoctors(sector: currentSector.value, limit: 5);
      topDoctors.value = doctors;

      final appointments = await _firestoreService.getPatientAppointments(user.uid);
      if (appointments.isNotEmpty) {
        // Strict filtering for Dashboard: Only Today or Future
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

        final upcomingList = appointments.where((a) {
          final isActive = a.status != 'Cancelled' && a.status != 'Completed';
          // Ensure appointment date is >= today
          final isUpcomingOrToday = a.appointmentDate.compareTo(todayStr) >= 0;
          return isActive && isUpcomingOrToday;
        }).toList();

        if (upcomingList.isNotEmpty) {
          upcomingList.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
          final rawAppt = upcomingList.first;

          final doctorData = await _firestoreService.getDoctor(rawAppt.doctorId);
          final hospitalData = await _firestoreService.getHospital(rawAppt.hospitalId);

          upcomingAppointment.value = rawAppt.copyWith(
            doctorName: doctorData?.doctorName ?? 'Doctor',
            specialization: doctorData?.specialization.join(', ') ?? 'Specialist',
            hospitalName: hospitalData?.hospitalName ?? 'Hospital',
          );
        } else {
          upcomingAppointment.value = null;
        }
      }
    } catch (e) {
      print("Dashboard Error: $e");
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void onSpecializationTapped(int index) {
    selectedSpecIndex.value = index;
    update();

    final spec = specializations[index];
    try {
      final searchCtrl = Get.find<DoctorSearchController>();
      searchCtrl.onSpecializationFilter(spec);
    } catch (e) {
      // If controller not found, it will handle it via arguments in next step
    }

    changeTab(1); // Switch to Search Tab
  }

  void changeTab(int index) {
    selectedIndex.value = index;
    if (index != 1) {
      selectedSpecIndex.value = -1;
    }
    update();
  }

  void onDoctorBookTapped(DoctorModel doctor) => Get.toNamed(AppRoutes.doctorProfile, arguments: {'doctor': doctor});
  void onViewAllAppointments() => changeTab(2); // Switch to History Tab
  void onSeeAllDoctors() {
    selectedSpecIndex.value = -1;
    try {
      final searchCtrl = Get.find<DoctorSearchController>();
      searchCtrl.clearFilters();
    } catch (e) {}
    changeTab(1); // Switch to Book Tab
  }

  void onSearchTapped() => changeTab(1); // Switch to Book Tab
  void onNotificationTapped() => Get.toNamed(AppRoutes.notifications);
  void onProfileTapped() => changeTab(3); // Switch to Profile Tab

  void changeSector(String sector) {
    currentSector.value = sector;
    selectedSpecIndex.value = -1;
    _loadDashboardData();
  }

  Future<void> onRefresh() async => await _loadDashboardData();
}
