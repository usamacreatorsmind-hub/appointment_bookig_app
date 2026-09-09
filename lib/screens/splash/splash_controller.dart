// File: lib/screens/splash/splash_controller.dart

import 'package:doctor_app/utils/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../Repository/auth_repository.dart';
import '../../models/user_model.dart';

class SplashController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();

  @override
  void onInit() {
    super.onInit();
    _checkInitialState();
  }

  void _checkInitialState() async {
    await Future.delayed(const Duration(seconds: 3));

    User? user = _authRepository.currentUser;

    if (user != null) {
      try {
        UserModel? userData = await _authRepository.getUserData(user.uid);

        if (userData != null) {
          _navigateToDashboard(userData);
        } else {
          Get.offAllNamed(AppRoutes.roleSelection);
        }
      } catch (e) {
        Get.offAllNamed(AppRoutes.login);
      }
    } else {
      Get.offAllNamed(AppRoutes.roleSelection);
    }
  }

  void _navigateToDashboard(UserModel user) {
    if (user.role == 'patient' || user.role == 'pet_owner' || user.role == 'visitor') {
      Get.offAllNamed(AppRoutes.patientDashboard);
    } else if (user.role == 'doctor' || user.role == 'veterinary_doctor') {
      Get.offAllNamed(AppRoutes.doctorDashboard);
    } else {
      Get.offAllNamed(AppRoutes.roleSelection);
    }
  }
}
