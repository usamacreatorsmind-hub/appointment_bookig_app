import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../Repository/auth_repository.dart';
import '../../../models/user_model.dart';
import '../../../models/doctor_model.dart';
import '../../../models/hospital_model.dart';
import '../../../utils/app_routes.dart';
import '../../../utils/helper.dart';
import '../../Login/login_controller.dart';

class DoctorRegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthRepository _authRepository = AuthRepository();

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();
  final experienceController = TextEditingController();
  final feeController = TextEditingController();
  final bookingFeeController = TextEditingController(text: '50');
  final bioController = TextEditingController();
  final clinicNameController = TextEditingController();

  // Selections
  final isLoading = false.obs;
  final isMasterLoading = false.obs;
  final isPasswordHidden = true.obs;

  final practiceType = 'hospital'.obs; // 'hospital' or 'clinic'
  final selectedSector = 'human'.obs; // 'human' | 'veterinary' | 'office'

  // Multiple Hospitals Selection
  final selectedHospitalIds = <String>[].obs;

  final selectedGender = 'male'.obs;
  final selectedConsultationMode = 'Offline'.obs; // Default to Offline

  // Master Data Lists (Fetched from Firestore)
  final hospitals = <HospitalModel>[].obs;
  final availableSpecializations = <String>[].obs;
  final availableQualifications = <String>[].obs; // Added
  final availableSymptoms = <String>[].obs;
  final availableDiseases = <String>[].obs;
  final availableLanguages = <String>['Hindi', 'English', 'Punjabi', 'Marathi', 'Gujarati', 'Tamil', 'Bengali'].obs;

  final selectedSpecializations = <String>[].obs;
  final selectedQualifications = <String>[].obs; // Added
  final selectedSymptoms = <String>[].obs;
  final selectedDiseases = <String>[].obs;
  final selectedLanguages = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    isMasterLoading.value = true;
    update();
    try {
      final results = await Future.wait([
        _firestoreService.getAllHospitals(),
        _firestoreService.getSpecializations(),
        _firestoreService.getSymptoms(),
        _firestoreService.getDiseases(),
        _firestoreService.getQualifications(), // Added
      ]);

      hospitals.assignAll(results[0] as List<HospitalModel>);



      availableSpecializations.assignAll(results[1] as List<String>);
      availableSymptoms.assignAll(results[2] as List<String>);
      availableDiseases.assignAll(results[3] as List<String>);
      availableQualifications.assignAll(results[4] as List<String>);

      print("DataGets hospitals  ${hospitals}");
      print("DataGets hospitals  ${availableSpecializations}");
      print("DataGets hospitals  ${availableSymptoms}");
      print("DataGets hospitals  ${availableDiseases}");
      print("DataGets hospitals  ${availableQualifications}");

      // Added
    } catch (e) {
      print("Error fetching master data: $e");
    } finally {
      isMasterLoading.value = false;
      update();
    }
  }

  void togglePasswordVisibility() => isPasswordHidden.value = !isPasswordHidden.value;
  void selectGender(String val) => selectedGender.value = val;
  void selectMode(String val) => selectedConsultationMode.value = val;

  void toggleHospital(String hospitalId) {
    if (selectedHospitalIds.contains(hospitalId)) {
      selectedHospitalIds.remove(hospitalId);
    } else {
      selectedHospitalIds.add(hospitalId);
    }
  }

  void toggleSelection(RxList<String> list, String value) {
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
  }

  Future<void> onRegisterPressed() async {
    if (!formKey.currentState!.validate()) return;
    
    if (practiceType.value == 'hospital' && selectedHospitalIds.isEmpty) {
      AppSnackBar.show('Please select at least one hospital');
      return;
    }

    if (practiceType.value == 'clinic' && clinicNameController.text.trim().isEmpty) {
      AppSnackBar.show('Please enter your clinic name');
      return;
    }

    if (selectedQualifications.isEmpty) {
      AppSnackBar.show('Please select at least one qualification');
      return;
    }
    if (selectedSpecializations.isEmpty) {
      AppSnackBar.show('Please select at least one specialization');
      return;
    }

    isLoading.value = true;
    update();

    try {
      // 1. Create Auth User
      UserCredential? userCredential = await _authRepository.signUpAuth(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (userCredential != null && userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        String finalHospitalId = '';
        List<String> finalHospitalIds = [];

        if (practiceType.value == 'clinic') {
          // Create a new Hospital record for the individual clinic
          final clinic = HospitalModel(
            hospitalId: '',
            adminUserId: uid,
            hospitalName: clinicNameController.text.trim(),
            registrationNo: 'CLINIC-${DateTime.now().millisecondsSinceEpoch}',
            address: 'To be updated',
            city: 'To be updated',
            state: 'To be updated',
            pincode: '',
            contactNumber: mobileController.text.trim(),
            email: emailController.text.trim(),
            departments: selectedSpecializations.toList(),
            workingHours: {'open': '09:00 AM', 'close': '08:00 PM'},
            emergencyAvailable: false,
            status: 'active',
            createdAt: DateTime.now(),
          );
          finalHospitalId = await _firestoreService.createHospital(clinic);
          finalHospitalIds = [finalHospitalId];
        } else {
          finalHospitalId = selectedHospitalIds.first;
          finalHospitalIds = selectedHospitalIds.toList();
        }

        // 2. Create Doctor Profile
        final doctor = DoctorModel(
          doctorId: '',
          uid: uid,
          hospitalId: finalHospitalId,
          hospitalIds: finalHospitalIds,
          doctorName: nameController.text.trim(),
          qualification: selectedQualifications.toList(),
          specialization: selectedSpecializations.toList(),
          experience: int.tryParse(experienceController.text) ?? 0,
          consultationFee: double.tryParse(feeController.text) ?? 0.0,
          bookingFee: double.tryParse(bookingFeeController.text) ?? 50.0,
          mobileNumber: mobileController.text.trim(),
          email: emailController.text.trim(),
          gender: selectedGender.value,
          languagesKnown: selectedLanguages.toList(),
          biography: bioController.text.trim(),
          symptomsCovered: selectedSymptoms.toList(),
          diseasesCovered: selectedDiseases.toList(),
          consultationMode: selectedConsultationMode.value,
          status: practiceType.value == 'clinic' ? 'active' : 'pending',
          practiceType: practiceType.value,
          sector: selectedSector.value,
          clinicName: practiceType.value == 'clinic' ? clinicNameController.text.trim() : null,
          createdAt: DateTime.now(),
        );

        final String doctorId = await _firestoreService.createDoctor(doctor);

        // 3. Create User Document
        String roleStr = 'doctor';
        if (selectedSector.value == 'veterinary') roleStr = 'veterinary_doctor';
        if (selectedSector.value == 'office') roleStr = 'office_staff';

        final userModel = UserModel(
          uid: uid,
          name: nameController.text.trim(),
          mobile: mobileController.text.trim(),
          email: emailController.text.trim(),
          role: roleStr,
          status: practiceType.value == 'clinic' ? 'active' : 'pending',
          doctorId: doctorId,
          hospitalId: finalHospitalId,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(userModel);

        // 4. Create Join Requests (Only for Hospital path)
        if (practiceType.value == 'hospital') {
          for (String hId in selectedHospitalIds) {
            await _firestoreService.createJoinRequest({
              'doctorId': doctorId,
              'doctorUid': uid,
              'hospitalId': hId,
              'doctorName': doctor.doctorName,
              'specialization': doctor.specialization,
              'doctorEmail': doctor.email,
              'doctorMobile': doctor.mobileNumber,
              'status': 'pending',
            });
          }
          AppSnackBar.show('Registration successful! Please wait for admin approval.');
        } else {
          AppSnackBar.show('Registration successful! Your clinic profile is ready.');
        }

        LoginRole loginRole = LoginRole.doctor;
        if (selectedSector.value == 'veterinary') loginRole = LoginRole.veterinaryDoctor;
        if (selectedSector.value == 'office') loginRole = LoginRole.officeStaff;

        Get.offAllNamed(AppRoutes.login, arguments: {'role': loginRole});
      }
    } catch (e) {
      AppSnackBar.show(e.toString());
    } finally {
      isLoading.value = false;
      update();
    }
  }

  String? validateName(String? v) => (v == null || v.isEmpty) ? 'Enter name' : null;
  String? validateEmail(String? v) => (v == null || !GetUtils.isEmail(v)) ? 'Invalid email' : null;
  String? validateMobile(String? v) => (v == null || v.length != 10) ? 'Enter 10-digit number' : null;
  String? validatePassword(String? v) => (v == null || v.length < 6) ? 'Min 6 characters' : null;
}
