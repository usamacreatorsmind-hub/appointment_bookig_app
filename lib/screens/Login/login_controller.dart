import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Repository/auth_repository.dart';
import '../../models/user_model.dart';
import '../../utils/app_routes.dart';
import '../../utils/helper.dart';
import '../role_selection/role_selection_controller.dart';
import '../../services/notification_service.dart';

enum LoginRole { 
  doctor, 
  veterinaryDoctor, 
  officeStaff, 
  patient, 
  visitor 
}

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final AuthRepository _authRepository = AuthRepository();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();

  final selectedRole = LoginRole.patient.obs;
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;
  final loginWithOtp = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['role'] != null) {
      if (args['role'] is UserRole) {
        final UserRole passedRole = args['role'] as UserRole;
        switch (passedRole) {
          case UserRole.doctor:
            selectedRole.value = LoginRole.doctor;
            break;
          case UserRole.veterinaryDoctor:
            selectedRole.value = LoginRole.veterinaryDoctor;
            break;
          case UserRole.officeStaff:
            selectedRole.value = LoginRole.officeStaff;
            break;
          case UserRole.patient:
            selectedRole.value = LoginRole.patient;
            break;
          case UserRole.visitor:
            selectedRole.value = LoginRole.visitor;
            break;
        }
      } else if (args['role'] is LoginRole) {
        selectedRole.value = args['role'];
      }
    }
    update();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
    update();
  }

  void toggleLoginMode() {
    loginWithOtp.value = !loginWithOtp.value;
    update();
  }

  Future<void> onLoginPressed() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    update();

    try {
      String loginIdentifier = emailController.text.trim();

      // If the input is a 10-digit mobile number, find the associated email first
      if (GetUtils.isPhoneNumber(loginIdentifier) && loginIdentifier.length == 10) {
        UserModel? userByMobile = await _authRepository.getUserByMobile(loginIdentifier);
        if (userByMobile != null) {
          loginIdentifier = userByMobile.email;
        } else {
          AppSnackBar.show("No account found with this mobile number.");
          isLoading.value = false;
          update();
          return;
        }
      }

      UserCredential? userCredential = await _authRepository.signIn(loginIdentifier, passwordController.text.trim());

      if (userCredential != null && userCredential.user != null) {
        final String uid = userCredential.user!.uid;
        final String email = userCredential.user!.email ?? emailController.text.trim();

        UserModel? userData = await _authRepository.getUserData(uid);

        if (userData == null) {
          userData = await _authRepository.getUserByEmail(email);
          if (userData != null) {
            String oldDocId = userData.uid;
            userData = userData.copyWith(uid: uid);
            await _authRepository.migrateUser(oldDocId, userData);
          }
        }

        // Update FCM Token immediately after login/migration
        await NotificationService.to.updateToken();

        if (userData != null) {
          // --- Role Validation ---
          String selectedRoleStr = _getRoleString(selectedRole.value);
          if (userData.role != selectedRoleStr) {
            await _authRepository.signOut();
            AppSnackBar.show('Access Denied: You are registered as a ${userData.role}. Please use the correct login screen.');
            isLoading.value = false;
            update();
            return;
          }
          // -----------------------

          AppSnackBar.show('Welcome back, ${userData.name}!');

          if (userData.role == 'patient' || userData.role == 'pet_owner' || userData.role == 'visitor') {
            Get.offAllNamed(AppRoutes.patientDashboard);
          } else if (userData.role == 'doctor' || userData.role == 'veterinary_doctor') {
            Get.offAllNamed(AppRoutes.doctorDashboard);
          } else {
            Get.offAllNamed(AppRoutes.roleSelection);
          }
        } else {
          AppSnackBar.show("User record not found in database. Please register.");
        }
      }
    } on FirebaseAuthException catch (e) {
      AppSnackBar.show(e.message ?? 'Login failed');
    } catch (e) {
      AppSnackBar.show(e.toString());
      print(e.toString());
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> onSendOtpPressed() async {
    if (mobileController.text.isEmpty || mobileController.text.length != 10) {
      AppSnackBar.show('Please enter a valid 10-digit mobile number');
      return;
    }

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
          'role': selectedRole.value,
          'isLogin': true,
          'isMsg91': true,
        },
      );
    } catch (e) {
      isLoading.value = false;
      update();
      AppSnackBar.show(e.toString());
    }
  }

  void goToRegister() => Get.toNamed(AppRoutes.register, arguments: {'role': selectedRole.value});
  void goToForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);

  String _getRoleString(LoginRole role) {
    switch (role) {
      case LoginRole.doctor:
        return 'doctor';
      case LoginRole.veterinaryDoctor:
        return 'veterinary_doctor';
      case LoginRole.officeStaff:
        return 'office_staff';
      case LoginRole.patient:
        return 'patient';
      case LoginRole.visitor:
        return 'visitor';
      default:
        return 'patient';
    }
  }

  String? validateEmail(String? value) => (value == null || !GetUtils.isEmail(value)) ? 'Invalid email' : null;
  String? validatePassword(String? value) => (value == null || value.length < 6) ? 'Min 6 characters' : null;
}
