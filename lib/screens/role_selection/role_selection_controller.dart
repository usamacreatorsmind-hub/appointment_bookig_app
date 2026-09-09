
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_routes.dart' show AppRoutes;
import '../../utils/helper.dart';

enum UserRole { 
  doctor, 
  veterinaryDoctor, 
  officeStaff, 
  patient, 
  visitor 
}

class RoleSelectionController extends GetxController {
  final selectedRole = Rxn<UserRole>();

  void selectRole(UserRole role) {
    selectedRole.value = role;
    update();
  }

  void onContinue() {
    if (selectedRole.value == null) {


      AppSnackBar.show('Please select your role to continue');
      return;
    }

    // Navigate to login and pass role as argument
    Get.toNamed(
      AppRoutes.login,
      arguments: {'role': selectedRole.value},
    );
  }
}
