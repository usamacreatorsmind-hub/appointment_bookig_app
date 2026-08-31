import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../firebase_options.dart';
import '../../../models/user_model.dart';
import '../../../utils/helper.dart';

class AddReceptionistController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;

  late String hospitalId;
  String? doctorId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map?;
    hospitalId = args?['hospitalId'] ?? '';
    doctorId = args?['doctorId'];
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> addReceptionist() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    update();

    FirebaseApp? secondaryApp;
    try {
      // 1. Initialize a secondary Firebase app to create user without logging out the current admin
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final FirebaseAuth secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 2. Create the Auth account
      UserCredential userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        // 3. Create the Firestore profile
        UserModel receptionist = UserModel(
          uid: userCredential.user!.uid,
          name: nameController.text.trim(),
          mobile: mobileController.text.trim(),
          email: emailController.text.trim(),
          role: 'receptionist',
          status: 'active',
          hospitalId: hospitalId,
          doctorId: doctorId,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createUser(receptionist);

        // 4. Sign out from secondary app and delete it
        await secondaryAuth.signOut();
        
        AppSnackBar.show('Receptionist added successfully!');
        Get.back(result: true);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        AppSnackBar.show('This email is already registered. If you previously deleted this staff, please ensure their account is also removed from Firebase Auth console.');
      } else {
        AppSnackBar.show(e.message ?? 'Failed to create account');
      }
    } catch (e) {
      AppSnackBar.show('Error: $e');
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
      isLoading.value = false;
      update();
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  String? validateEmail(String? value) => (value == null || !GetUtils.isEmail(value)) ? 'Invalid email' : null;
  String? validateMobile(String? value) => (value == null || value.length != 10) ? 'Enter 10-digit mobile' : null;
  String? validatePassword(String? value) => (value == null || value.length < 6) ? 'Min 6 characters' : null;
}
