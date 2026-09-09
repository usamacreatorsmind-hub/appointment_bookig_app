// File: lib/screens/doctor/profile/doctor_self_profile_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../Repository/auth_repository.dart';
import '../../../models/doctor_model.dart';
import '../../../models/hospital_model.dart';
import '../../../utils/app_routes.dart';
import '../../../utils/helper.dart';

class DoctorSelfProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthRepository _authRepository = AuthRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final isLoading = false.obs;
  final isMasterLoading = false.obs;
  final isEditing = false.obs;
  final doctorProfile = Rxn<DoctorModel>();

  // Master Data Lists
  final hospitals = <HospitalModel>[].obs;
  final availableSpecializations = <String>[].obs;
  final availableQualifications = <String>[].obs;
  final availableSymptoms = <String>[].obs;
  final availableDiseases = <String>[].obs;
  final availableLanguages = <String>['Hindi', 'English', 'Punjabi', 'Marathi', 'Gujarati', 'Tamil', 'Bengali'].obs;

  // Form Controllers
  late TextEditingController nameController;
  late TextEditingController experienceController;
  late TextEditingController feeController;
  late TextEditingController bioController;
  late TextEditingController mobileController;
  late TextEditingController clinicNameController;

  // Selected values
  final selectedHospitalIds = <String>[].obs;
  final selectedSpecializations = <String>[].obs;
  final selectedQualifications = <String>[].obs;
  final selectedSymptoms = <String>[].obs;
  final selectedDiseases = <String>[].obs;
  final selectedLanguages = <String>[].obs;

  final selectedGender = 'male'.obs;
  final selectedConsultationMode = 'Offline'.obs; // Only Offline supported

  final pickedImage = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    experienceController = TextEditingController();
    feeController = TextEditingController();
    bioController = TextEditingController();
    mobileController = TextEditingController();
    clinicNameController = TextEditingController();
    loadInitialData();
  }

  @override
  void onClose() {
    nameController.dispose();
    experienceController.dispose();
    feeController.dispose();
    bioController.dispose();
    mobileController.dispose();
    clinicNameController.dispose();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    update();
    try {
      await fetchMasterData();
      await loadProfile();
    } catch (e) {
      print("Error loading initial data: $e");
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> fetchMasterData() async {
    isMasterLoading.value = true;
    update();
    try {
      final results = await Future.wait([
        _firestoreService.getAllHospitals(),
        _firestoreService.getSpecializations(),
        _firestoreService.getSymptoms(),
        _firestoreService.getDiseases(),
        _firestoreService.getQualifications(),
      ]);

      hospitals.assignAll(results[0] as List<HospitalModel>);
      availableSpecializations.assignAll(results[1] as List<String>);
      availableSymptoms.assignAll(results[2] as List<String>);
      availableDiseases.assignAll(results[3] as List<String>);
      availableQualifications.assignAll(results[4] as List<String>);
    } catch (e) {
      print("Error fetching master data: $e");
    } finally {
      isMasterLoading.value = false;
      update();
    }
  }

  Future<void> loadProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint("DoctorProfile: Loading profile for UID: ${user.uid}");
        final profile = await _firestoreService.getDoctorByUid(user.uid);

        if (profile != null) {
          debugPrint("DoctorProfile: Profile found in doctors collection");
          doctorProfile.value = profile;
          _fillControllers(profile);
        } else {
          debugPrint("DoctorProfile: Profile NOT found in doctors collection, trying fallback to users");
          // Fallback to UserModel for basic info
          final userModel = await _firestoreService.getUser(user.uid);
          if (userModel != null) {
            debugPrint("DoctorProfile: User model found, creating skeleton doctor profile");
            final skeleton = DoctorModel(
              doctorId: '',
              uid: userModel.uid,
              hospitalId: userModel.hospitalId ?? '',
              hospitalIds: userModel.hospitalId != null ? [userModel.hospitalId!] : [],
              doctorName: userModel.name,
              qualification: [],
              specialization: [],
              experience: 0,
              consultationFee: 0.0,
              mobileNumber: userModel.mobile,
              email: userModel.email,
              gender: 'male',
              languagesKnown: [],
              status: userModel.status,
              createdAt: userModel.createdAt,
              symptomsCovered: [],
              diseasesCovered: [],
              consultationMode: 'Offline',
            );
            doctorProfile.value = skeleton;
            _fillControllers(skeleton);
          }
        }
      }
    } catch (e) {
      debugPrint("DoctorProfile Error: $e");
      AppSnackBar.show('Failed to load profile: $e');
    }
  }

  void _fillControllers(DoctorModel profile) {
    nameController.text = profile.doctorName;
    experienceController.text = profile.experience.toString();
    feeController.text = profile.consultationFee.toString();
    bioController.text = profile.biography ?? '';
    mobileController.text = profile.mobileNumber;
    clinicNameController.text = profile.clinicName ?? '';

    selectedGender.value = profile.gender;
    selectedConsultationMode.value = profile.consultationMode;

    selectedHospitalIds.assignAll(profile.hospitalIds);
    selectedSpecializations.assignAll(profile.specialization);
    selectedQualifications.assignAll(profile.qualification);
    selectedLanguages.assignAll(profile.languagesKnown);
    selectedSymptoms.assignAll(profile.symptomsCovered);
    selectedDiseases.assignAll(profile.diseasesCovered);
    pickedImage.value = null;
  }

  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value && doctorProfile.value != null) {
      _fillControllers(doctorProfile.value!);
    }
    update();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (image != null) {
      pickedImage.value = File(image.path);
      update();
    }
  }

  void toggleSelection(RxList<String> list, String value) {
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
  }

  Future<void> updateProfile() async {
    if (doctorProfile.value == null) return;

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
      final String uid = doctorProfile.value!.uid;
      String? photoUrl = doctorProfile.value?.photoUrl;

      if (pickedImage.value != null) {
        debugPrint("DoctorProfile: Uploading image to Storage...");
        try {
          final ref = _storage.ref().child('doctor_profiles').child(uid).child('profile.jpg');
          await ref.putFile(pickedImage.value!);
          photoUrl = await ref.getDownloadURL();
        } catch (e) {
          debugPrint("DoctorProfile Storage Error: $e");
          // Continue without updating photo if storage fails (maybe not enabled)
          AppSnackBar.show('Photo upload failed. Please ensure Firebase Storage is enabled.');
        }
      }

      final data = {
        'uid': uid,
        'doctorName': nameController.text.trim(),
        'qualification': selectedQualifications.toList(),
        'specialization': selectedSpecializations.toList(),
        'experience': int.tryParse(experienceController.text) ?? 0,
        'consultationFee': double.tryParse(feeController.text) ?? 0.0,
        'mobileNumber': mobileController.text.trim(),
        'gender': selectedGender.value,
        'languagesKnown': selectedLanguages.toList(),
        'biography': bioController.text.trim(),
        'consultationMode': selectedConsultationMode.value,
        'hospitalIds': selectedHospitalIds.toList(),
        'hospitalId': selectedHospitalIds.isNotEmpty ? selectedHospitalIds.first : '',
        'clinicName': clinicNameController.text.trim(),
        'symptomsCovered': selectedSymptoms.toList(),
        'diseasesCovered': selectedDiseases.toList(),
        'photoUrl': photoUrl,
        'photo': photoUrl,
        'sector': doctorProfile.value?.sector ?? 'human',
        'category': doctorProfile.value?.category ?? 'General',
      };

      if (doctorProfile.value!.doctorId.isEmpty) {
        debugPrint("DoctorProfile: Creating new doctor document...");
        final newId = await _firestoreService.createDoctor(DoctorModel.fromMap(data, ''));
        // Link to user model
        await _firestoreService.updateUser(uid, {'doctorId': newId});
        debugPrint("DoctorProfile: New doctor created with ID: $newId");
      } else {
        debugPrint("DoctorProfile: Updating existing doctor document: ${doctorProfile.value!.doctorId}");
        await _firestoreService.updateDoctor(doctorProfile.value!.doctorId, data);
      }

      await loadProfile();
      isEditing.value = false;
      AppSnackBar.show('Profile updated successfully');
    } catch (e) {
      debugPrint("DoctorProfile Update Error: $e");
      AppSnackBar.show('Failed to update profile: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> signOut() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _authRepository.signOut();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
