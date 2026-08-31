import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/doctor_model.dart';
import '../../../models/appointment_model.dart';
import '../../../models/notification_model.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../services/booking_service.dart';
import '../../../utils/app_routes.dart';
import '../../../utils/helper.dart';

class BookingConfirmController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final BookingService _bookingService = BookingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late DoctorModel doctor;
  late String selectedDateStr;
  late String selectedTimeSlot;

  final isLoading = false.obs;
  final hospitalName = ''.obs;
  final consultationType = 'Offline'.obs; // Always Offline for now
  final patientSymptoms = ''.obs;

  // Third Person Booking
  final isForSelf = true.obs;
  final otherNameController = TextEditingController();
  final otherAgeController = TextEditingController();
  final otherMobileController = TextEditingController();
  final otherGuardianController = TextEditingController();
  final otherAddressController = TextEditingController();
  final selectedGender = 'Male'.obs;
  final selectedRelationship = 'Father'.obs;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> relationships = ['Father', 'Mother', 'Spouse', 'Sibling', 'Child', 'Friend', 'Other'];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['doctor'] != null) {
      doctor = args['doctor'];
      selectedDateStr = args['selectedDate'];
      selectedTimeSlot = args['selectedTimeSlot'];
      _loadHospitalName();
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    otherNameController.dispose();
    otherAgeController.dispose();
    otherMobileController.dispose();
    otherGuardianController.dispose();
    otherAddressController.dispose();
    super.onClose();
  }

  Future<void> _loadHospitalName() async {
    final h = await _firestoreService.getHospital(doctor.hospitalId);
    if (h != null) hospitalName.value = h.hospitalName;
  }

  void updatePatientSymptoms(String s) => patientSymptoms.value = s;

  Future<void> confirmBooking() async {
    if (_auth.currentUser == null) return;

    if (!isForSelf.value) {
      if (otherNameController.text.trim().isEmpty) {
        AppSnackBar.show('Please enter patient name');
        return;
      }
      if (otherAgeController.text.trim().isEmpty) {
        AppSnackBar.show('Please enter patient age');
        return;
      }
      if (otherGuardianController.text.trim().isEmpty) {
        AppSnackBar.show('Please enter parents/guardian name');
        return;
      }
      if (otherAddressController.text.trim().isEmpty) {
        AppSnackBar.show('Please enter address');
        return;
      }
    }

    isLoading.value = true;
    update();

    try {
      final user = await _firestoreService.getUser(_auth.currentUser!.uid);
      final currentUserName = user?.name ?? 'Patient';

      // Fetch Token and Patient Type
      final token = await _bookingService.getNextTokenNumber(doctor.doctorId, selectedDateStr);
      final pType = await _bookingService.checkPatientType(_auth.currentUser!.uid, doctor.doctorId);

      final appt = AppointmentModel(
        appointmentId: '',
        patientId: _auth.currentUser!.uid,
        doctorId: doctor.doctorId,
        hospitalId: doctor.hospitalId,
        appointmentDate: selectedDateStr,
        timeSlot: selectedTimeSlot,
        consultationType: consultationType.value,
        symptoms: patientSymptoms.value,
        status: 'Pending',
        paymentStatus: 'Unpaid',
        fee: doctor.consultationFee,
        isForSelf: isForSelf.value,
        tokenNumber: token,
        patientType: pType,
        patientDetails: isForSelf.value
            ? null
            : {
                'name': otherNameController.text.trim(),
                'age': otherAgeController.text.trim(),
                'gender': selectedGender.value,
                'guardianName': otherGuardianController.text.trim(),
                'address': otherAddressController.text.trim(),
                'mobile': otherMobileController.text.trim(),
                'relationship': selectedRelationship.value,
              },
        createdAt: DateTime.now(),
      );

      final patientName = isForSelf.value ? currentUserName : otherNameController.text.trim();

      final apptId = await _firestoreService.createAppointment(appt);

      await _firestoreService.createNotification(
        NotificationModel(
          notificationId: '',
          userId: doctor.uid,
          title: 'New Appointment',
          message: 'A new appointment has been booked for $selectedDateStr',
          type: 'appointment',
          channel: 'app',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      Get.offNamed(AppRoutes.payment, arguments: {
        'appointmentId': apptId,
        'amount': doctor.consultationFee,
        'bookingFee': doctor.bookingFee,
        'doctorName': doctor.doctorName,
        'patientName': patientName,
        'date': selectedDateStr,
        'time': selectedTimeSlot,
      });
    } catch (e) {
      AppSnackBar.show('Booking failed: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
