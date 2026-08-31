import 'package:get/get.dart';
import '../../../Repository/auth_repository.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../models/appointment_model.dart';
import '../../../models/user_model.dart';
import '../../../utils/helper.dart';

class ReceptionistAppointmentsController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreService _firestoreService = FirestoreService();

  final RxList<AppointmentModel> appointments = <AppointmentModel>[].obs;
  final isLoading = false.obs;
  final selectedDate = DateTime.now().obs;
  final searchQuery = ''.obs;
  UserModel? _currentUser;

  @override
  void onInit() {
    super.onInit();
    // Check if a date was passed from the dashboard
    if (Get.arguments != null && Get.arguments['date'] != null) {
      selectedDate.value = Get.arguments['date'];
    }
    _loadAppointments();
  }

  // Computed list for UI
  List<AppointmentModel> get filteredAppointments {
    if (searchQuery.value.isEmpty) {
      return appointments;
    }
    return appointments.where((a) {
      final name = (a.patientName ?? '').toLowerCase();
      final query = searchQuery.value.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  Future<void> selectDate(DateTime date) async {
    selectedDate.value = date;
    await _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    isLoading.value = true;
    try {
      if (_currentUser == null) {
        final authUser = _authRepository.currentUser;
        if (authUser != null) {
          _currentUser = await _authRepository.getUserData(authUser.uid);
        }
      }

      if (_currentUser?.hospitalId != null) {
        final dateStr = selectedDate.value.toIso8601String().split('T')[0];
        final data = await _firestoreService.getHospitalAppointments(_currentUser!.hospitalId!, date: dateStr);
        
        List<AppointmentModel> filteredData = [];

        // Filter by Doctor if this is a clinic/doctor receptionist
        if (_currentUser?.doctorId != null) {
          filteredData = data.where((a) => a.doctorId == _currentUser!.doctorId).toList();
        } else {
          filteredData = data;
        }

        // Enhance with names
        List<AppointmentModel> enhancedList = [];
        for (var appt in filteredData) {
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
            enhancedList.add(appt.copyWith(
              patientName: 'Patient',
              doctorName: 'Doctor',
            ));
          }
        }

        // Sort: Arrived first, then by token number, then by time
        enhancedList.sort((a, b) {
          if (a.status == 'Arrived' && b.status != 'Arrived') return -1;
          if (a.status != 'Arrived' && b.status == 'Arrived') return 1;
          
          if (a.tokenNumber != null && b.tokenNumber != null) {
            return a.tokenNumber!.compareTo(b.tokenNumber!);
          }
          return a.timeSlot.compareTo(b.timeSlot);
        });

        appointments.assignAll(enhancedList);
      }
    } catch (e) {
      AppSnackBar.show('Error loading appointments: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateStatus(String appointmentId, String newStatus) async {
    try {
      await _firestoreService.updateAppointmentStatus(appointmentId, newStatus);
      
      // Update local list
      int index = appointments.indexWhere((a) => a.appointmentId == appointmentId);
      if (index != -1) {
        appointments[index] = appointments[index].copyWith(status: newStatus);
      }
      
      AppSnackBar.show('Appointment marked as $newStatus');
    } catch (e) {
      AppSnackBar.show('Error updating status: $e');
    }
  }

  Future<void> markAsPaid(String appointmentId) async {
    try {
      await _firestoreService.updateAppointment(appointmentId, {'paymentStatus': 'Paid'});
      
      // Update local list
      int index = appointments.indexWhere((a) => a.appointmentId == appointmentId);
      if (index != -1) {
        appointments[index] = appointments[index].copyWith(paymentStatus: 'Paid');
      }
      
      AppSnackBar.show('Payment marked as Paid');
    } catch (e) {
      AppSnackBar.show('Error updating payment: $e');
    }
  }
}
