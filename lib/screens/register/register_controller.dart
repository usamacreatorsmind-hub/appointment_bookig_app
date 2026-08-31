import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Repository/auth_repository.dart';
import '../../utils/app_routes.dart';
import '../../utils/helper.dart';
import '../Login/login_controller.dart' show LoginRole;

enum Gender { male, female, other }

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final dobController = TextEditingController();

  final selectedGender = Gender.male.obs;
  final selectedBloodGroup = 'A+'.obs;
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;

  final List<String> bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void onClose() {
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    passwordController.dispose();
    dobController.dispose();
    super.onClose();
  }

  void selectGender(Gender gender) {
    selectedGender.value = gender;
    update(); // Rebuild GetBuilder
  }

  void selectBloodGroup(String bg) {
    selectedBloodGroup.value = bg;
    update(); // Rebuild GetBuilder
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
    update(); // Rebuild GetBuilder
  }

  Future<void> pickDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      update();
    }
  }

  Future<void> onRegisterPressed() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    update();

    try {
      await _authRepository.sendMsg91Otp(mobileController.text.trim());
      isLoading.value = false;
      update();

      Get.toNamed(
        AppRoutes.otpVerification,
        arguments: {
          'mobile': mobileController.text.trim(),
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'role': LoginRole.patient,
          'isLogin': false,
          'isMsg91': true,
          'dob': dobController.text,
          'gender': selectedGender.value.name,
          'bloodGroup': selectedBloodGroup.value,
        },
      );
    } catch (e) {
      isLoading.value = false;
      update();

      AppSnackBar.show(e.toString());
    }
  }

  void goToLogin() => Get.back();

  String? validateName(String? v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null;
  String? validateMobile(String? v) =>
      (v == null || v.length != 10) ? 'Enter 10-digit number' : null;
  String? validateEmail(String? v) => (v == null || !GetUtils.isEmail(v)) ? 'Invalid email' : null;
  String? validatePassword(String? v) => (v == null || v.length < 6) ? 'Min 6 characters' : null;
}
