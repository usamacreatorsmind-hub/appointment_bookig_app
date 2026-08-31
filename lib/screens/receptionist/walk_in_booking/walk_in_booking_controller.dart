import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../Repository/auth_repository.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../firebase_options.dart';
import '../../../models/user_model.dart';
import '../../../models/doctor_model.dart';
import '../../../models/appointment_model.dart';
import '../../../models/doctor_schedule_model.dart';
import '../../../models/patient_profile_model.dart';
import '../../../services/booking_service.dart';
import '../../../utils/helper.dart';

class WalkInBookingController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreService _firestoreService = FirestoreService();
  final BookingService _bookingService = BookingService();

  // State
  final currentStep = 0.obs;
  final isLoading = false.obs;
  UserModel? receptionistUser;

  // Search Step
  final mobileController = TextEditingController();
  UserModel? foundPatient;

  // Registration Step (if needed)
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final selectedGender = 'male'.obs;

  // Booking Step
  final RxList<DoctorModel> doctors = <DoctorModel>[].obs;
  final selectedDoctor = Rxn<DoctorModel>();
  final selectedDate = DateTime.now().obs;
  final RxList<String> availableSlots = <String>[].obs;
  final RxList<String> bookedSlots = <String>[].obs;
  final selectedSlot = Rxn<String>();
  final symptomsController = TextEditingController();

  // Family Member Booking
  final isForSelf = true.obs;
  final otherNameController = TextEditingController();
  final otherAgeController = TextEditingController();
  final selectedOtherGender = 'Male'.obs;
  final selectedRelationship = 'Child'.obs;

  final List<String> genders = ['Male', 'Female', 'Other'];
  final List<String> relationships = ['Father', 'Mother', 'Spouse', 'Sibling', 'Child', 'Friend', 'Other'];

  @override
  void onInit() {
    super.onInit();
    _loadReceptionistData();
  }

  Future<void> _loadReceptionistData() async {
    final authUser = _authRepository.currentUser;
    if (authUser != null) {
      receptionistUser = await _authRepository.getUserData(authUser.uid);
      if (receptionistUser?.hospitalId != null) {
        _loadDoctors();
      }
    }
  }

  Future<void> _loadDoctors() async {
    if (receptionistUser?.hospitalId == null) return;
    
    // If linked to a specific doctor (Clinic/PA mode)
    if (receptionistUser?.doctorId != null) {
      final doc = await _firestoreService.getDoctor(receptionistUser!.doctorId!);
      if (doc != null) {
        doctors.value = [doc];
        onDoctorSelected(doc); // Auto-select
      }
    } else {
      // Hospital mode - load all doctors
      final list = await _firestoreService.getDoctorsByHospital(receptionistUser!.hospitalId!);
      doctors.value = list;
    }
  }

  Future<void> searchPatient() async {
    if (mobileController.text.length != 10) {
      AppSnackBar.show('Enter a valid 10-digit mobile number');
      return;
    }

    isLoading.value = true;
    try {
      foundPatient = await _firestoreService.getUserByMobile(mobileController.text.trim());
      if (foundPatient != null) {
        currentStep.value = 2; // Skip registration
      } else {
        currentStep.value = 1; // Go to registration
      }
    } catch (e) {
      AppSnackBar.show('Search error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> registerAndContinue() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      AppSnackBar.show('Please fill all fields');
      return;
    }

    isLoading.value = true;
    FirebaseApp? secondaryApp;
    try {
      // Create account using Secondary App to avoid logging out receptionist
      secondaryApp = await Firebase.initializeApp(name: 'PatientRegApp', options: DefaultFirebaseOptions.currentPlatform);
      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final String tempPassword = 'Patient@123';
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(email: emailController.text.trim(), password: tempPassword);

      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          name: nameController.text.trim(),
          mobile: mobileController.text.trim(),
          email: emailController.text.trim(),
          role: 'patient',
          status: 'active',
          patientId: 'PAT-${const Uuid().v4().substring(0, 8)}',
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(newUser);

        // Save Patient Profile details (Gender, DOB)
        final profile = PatientProfileModel(gender: selectedGender.value, dob: dobController.text.trim(), updatedAt: DateTime.now());
        await _firestoreService.savePatientProfile(newUser.uid, profile);

        await secondaryAuth.signOut();

        foundPatient = newUser;
        currentStep.value = 2; // Go to booking
      }
    } catch (e) {
      AppSnackBar.show('Registration error: $e');
    } finally {
      if (secondaryApp != null) await secondaryApp.delete();
      isLoading.value = false;
    }
  }

  void onDoctorSelected(DoctorModel? doc) async {
    selectedDoctor.value = doc;
    selectedSlot.value = null;
    availableSlots.clear();
    bookedSlots.clear();

    if (doc != null) {
      isLoading.value = true;
      try {
        final schedules = await _firestoreService.getDoctorSchedules(doc.doctorId);
        final String dayOfWeek = _getDayFromDate(selectedDate.value);

        final todaysSchedule = schedules.firstWhereOrNull((s) => s.day.toLowerCase() == dayOfWeek.toLowerCase());

        if (todaysSchedule != null) {
          final allSlots24 = todaysSchedule.generateSlots(forDate: selectedDate.value);
          final allSlots12 = allSlots24.map((s24) {
            try {
              final time = DateFormat('HH:mm').parse(s24);
              return DateFormat('hh:mm a').format(time);
            } catch (e) {
              return s24;
            }
          }).toList();

          final dateStr = selectedDate.value.toIso8601String().split('T')[0];
          final booked = await _firestoreService.getBookedSlots(doc.doctorId, dateStr);

          availableSlots.value = allSlots12;
          bookedSlots.value = booked;
        } else {
          AppSnackBar.show('No schedule found for this doctor on selected day');
        }
      } catch (e) {
        AppSnackBar.show('Error loading slots: $e');
      } finally {
        isLoading.value = false;
      }
    }
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    onDoctorSelected(selectedDoctor.value);
  }

  String _getDayFromDate(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Future<void> bookAppointment() async {
    if (selectedDoctor.value == null || selectedSlot.value == null) {
      AppSnackBar.show('Select a doctor and time slot');
      return;
    }

    if (!isForSelf.value) {
      if (otherNameController.text.trim().isEmpty) {
        AppSnackBar.show('Please enter family member name');
        return;
      }
      if (otherAgeController.text.trim().isEmpty) {
        AppSnackBar.show('Please enter age');
        return;
      }
    }

    isLoading.value = true;
    try {
      final patientName = isForSelf.value ? foundPatient!.name : otherNameController.text.trim();
      final dateStr = selectedDate.value.toIso8601String().split('T')[0];

      // Fetch Token and Patient Type
      final token = await _bookingService.getNextTokenNumber(selectedDoctor.value!.doctorId, dateStr);
      final pType = await _bookingService.checkPatientType(foundPatient!.uid, selectedDoctor.value!.doctorId);

      final appt = AppointmentModel(
        appointmentId: '', // Firestore will generate
        patientId: foundPatient!.uid,
        patientName: patientName,
        doctorId: selectedDoctor.value!.doctorId,
        doctorName: selectedDoctor.value!.doctorName,
        hospitalId: receptionistUser!.hospitalId!,
        appointmentDate: dateStr,
        timeSlot: selectedSlot.value!,
        consultationType: 'Offline',
        symptoms: symptomsController.text.trim(),
        status: 'Confirmed', // Receptionist bookings are auto-confirmed
        paymentStatus: 'Unpaid',
        fee: selectedDoctor.value!.consultationFee,
        isForSelf: isForSelf.value,
        tokenNumber: token,
        patientType: pType,
        patientDetails: isForSelf.value
            ? null
            : {
                'name': otherNameController.text.trim(),
                'age': otherAgeController.text.trim(),
                'gender': selectedOtherGender.value,
                'relationship': selectedRelationship.value,
              },
        createdAt: DateTime.now(),
      );

      await _firestoreService.createAppointment(appt);
      Get.back(); // Go back to dashboard
      AppSnackBar.show('Walk-in booking successful');
    } catch (e) {
      AppSnackBar.show('Booking error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    mobileController.dispose();
    nameController.dispose();
    emailController.dispose();
    dobController.dispose();
    symptomsController.dispose();
    otherNameController.dispose();
    otherAgeController.dispose();
    super.onClose();
  }
}
