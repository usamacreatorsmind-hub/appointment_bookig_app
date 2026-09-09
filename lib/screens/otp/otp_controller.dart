import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Repository/auth_repository.dart';
import '../../Repository/FirestoreService.dart';
import '../../models/user_model.dart';
import '../../models/patient_profile_model.dart';
import '../../utils/app_routes.dart';
import '../../utils/helper.dart';
import '../../services/notification_service.dart';
import '../Login/login_controller.dart' show LoginRole;

class OtpController extends GetxController {
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreService _firestoreService = FirestoreService();

  late String mobileNumber;
  late LoginRole role;
  late bool isLogin;
  bool isForgotPassword = false;
  bool isMsg91 = false;
  String? verificationId;

  String? name, email, password, dob, gender, bloodGroup;

  final otpController = TextEditingController();
  final focusNode = FocusNode();

  final RxInt timerSeconds = 30.obs;
  final RxBool canResend = false.obs;
  Timer? _timer;

  final RxBool isLoading = false.obs;
  final RxString enteredOtp = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      mobileNumber = args['mobile'] ?? '';
      role = args['role'] ?? LoginRole.patient;
      isLogin = args['isLogin'] ?? true;
      isForgotPassword = args['isForgotPassword'] ?? false;
      isMsg91 = args['isMsg91'] ?? false;
      verificationId = args['verificationId'];

      if (!isLogin) {
        name = args['name'];
        email = args['email'];
        password = args['password'];
        dob = args['dob'];
        gender = args['gender'];
        bloodGroup = args['bloodGroup'];
      }
    }
    _startTimer();
  }

  void _startTimer() {
    timerSeconds.value = 30;
    canResend.value = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  String get timerDisplay {
    final m = timerSeconds.value ~/ 60;
    final s = timerSeconds.value % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get isOtpComplete => enteredOtp.value.length == (isMsg91 ? 4 : 6);

  Future<void> verifyOtp([String? pin]) async {
    final code = pin ?? otpController.text;
    if (code.isEmpty) return;
    if (isMsg91) {
      if (code.length != 4) return;
    } else {
      if (code.length != 6) return;
    }

    isLoading.value = true;
    update();

    debugPrint("--- OTP Verification Started ---");
    debugPrint("Mobile: $mobileNumber");
    debugPrint("Entered OTP: $code");
    debugPrint("Login Mode: $isLogin");
    debugPrint("Is MSG91: $isMsg91");

    try {
      UserCredential? userCredential;

      if (isMsg91) {
        debugPrint("Calling verifyMsg91Otp Cloud Function...");
        final result = await _authRepository.verifyMsg91Otp(mobileNumber, code);
        debugPrint("Cloud Function Result: $result");

        if (isLogin || isForgotPassword) {
          if (result['isRegistered'] == true && result['customToken'] != null) {
            userCredential = await _authRepository.signInWithCustomToken(result['customToken']);
          } else {
            AppSnackBar.show("User record not found. Please register.");
            isLoading.value = false;
            update();
            return;
          }
        }
      } else {
        final phoneAuthCredential = PhoneAuthProvider.credential(verificationId: verificationId!, smsCode: code);
        if (isForgotPassword || isLogin) {
          userCredential = await FirebaseAuth.instance.signInWithCredential(phoneAuthCredential);
        }
      }

      if (isForgotPassword) {
        if (userCredential?.user != null) {
          Get.offNamed(AppRoutes.resetPassword);
        }
      } else if (isLogin) {
        if (userCredential?.user != null) {
          final String uid = userCredential!.user!.uid;
          await NotificationService.to.updateToken();

          UserModel? userData = await _firestoreService.getUser(uid);

          if (userData == null) {
            userData = await _authRepository.getUserByMobile(mobileNumber);
            if (userData != null) {
              String oldDocId = userData.uid;
              userData = userData.copyWith(uid: uid);
              await _authRepository.migrateUser(oldDocId, userData);
              debugPrint("User migrated from $oldDocId to $uid via OTP Login");
            }
          }

          if (userData != null) {
            String selectedRoleStr = _getRoleString(role);
            if (userData.role != selectedRoleStr) {
              await _authRepository.signOut();
              AppSnackBar.show('Access Denied: You are registered as a ${userData.role}.');
              isLoading.value = false;
              update();
              return;
            }
            _navigateAfterVerification(userData.role);
          } else {
            AppSnackBar.show("User record not found in database. Please register.");
          }
        }
      } else {
        // Registration Flow
        final emailCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email!, password: password!);

        if (emailCredential.user != null) {
          if (!isMsg91) {
            try {
              final phoneAuthCredential = PhoneAuthProvider.credential(verificationId: verificationId!, smsCode: code);
              await emailCredential.user!.linkWithCredential(phoneAuthCredential);
            } catch (e) {
              debugPrint("Phone linking failed : $e");
            }
          }

          UserModel newUser = UserModel(
            uid: emailCredential.user!.uid,
            name: name!,
            email: email!,
            mobile: mobileNumber,
            role: _getRoleString(role),
            status: 'active',
            createdAt: DateTime.now(),
          );

          await _firestoreService.createUser(newUser);
          await NotificationService.to.updateToken();

          if (role == LoginRole.patient) {
            PatientProfileModel profile = PatientProfileModel(
              dob: dob ?? '',
              gender: gender ?? '',
              bloodGroup: bloodGroup ?? '',
              isProfileComplete: true,
            );
            await _firestoreService.savePatientProfile(newUser.uid, profile);
          }
          
          Get.offAllNamed(AppRoutes.languageSelection);
          AppSnackBar.show('Account created successfully!');
        }
      }
    } on FirebaseAuthException catch (e) {
      AppSnackBar.show(e.message ?? 'Verification failed');
    } on FirebaseFunctionsException catch (e) {
      debugPrint("--- Cloud Function Exception ---");
      debugPrint("Code: ${e.code}");
      debugPrint("Message: ${e.message}");
      debugPrint("Details: ${e.details}");
      // If it's internal, show the details (which we just added to the Cloud Function)
      String displayMsg = e.message ?? 'Verification failed';
      if (e.code == 'internal' && e.details != null) {
        displayMsg = "${e.message} (${e.details})";
      }
      AppSnackBar.show(displayMsg);
    } catch (e) {
      debugPrint("--- Generic Exception ---");
      debugPrint(e.toString());
      String msg = e.toString();
      if (msg.contains('OTP not match')) {
        msg = 'Invalid OTP. Please check and try again.';
      } else if (msg.contains('Exception:')) {
        msg = msg.split('Exception:').last.trim();
      }
      AppSnackBar.show(msg);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void _navigateAfterVerification(String roleStr) {
    if (roleStr == 'patient') {
      Get.offAllNamed(AppRoutes.patientDashboard);
    } else if (roleStr == 'doctor' || roleStr == 'veterinary_doctor') {
      Get.offAllNamed(AppRoutes.doctorDashboard);
    } else if (roleStr == 'receptionist') {
      Get.offAllNamed(AppRoutes.receptionistDashboard);
    } else {
      Get.offAllNamed(AppRoutes.roleSelection);
    }
  }

  Future<void> resendOtp() async {
    if (!canResend.value) return;
    isLoading.value = true;
    update();
    try {
      if (isMsg91) {
        await _authRepository.sendMsg91Otp(mobileNumber);
        _startTimer();
        AppSnackBar.show('New code sent to +91 $mobileNumber');
      } else {
        await _authRepository.verifyPhoneNumber(
          mobileNumber,
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) => AppSnackBar.show(e.message ?? 'Verification failed'),
          codeSent: (String vId, int? resendToken) {
            verificationId = vId;
            _startTimer();
            AppSnackBar.show('New code sent to +91 $mobileNumber');
          },
          codeAutoRetrievalTimeout: (String vId) {},
        );
      }
    } catch (e) {
      AppSnackBar.show(e.toString());
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void goBack() => Get.back();

  String _getRoleString(LoginRole role) {
    switch (role) {
      case LoginRole.doctor:
        return 'doctor';
      case LoginRole.patient:
        return 'patient';
      case LoginRole.receptionist:
        return 'receptionist';
      case LoginRole.veterinaryDoctor:
        return 'veterinary_doctor';
      case LoginRole.petOwner:
        return 'pet_owner';
      case LoginRole.officeStaff:
        return 'office_staff';
      case LoginRole.visitor:
        return 'visitor';
    }
    return 'patient';
  }

  @override
  void onClose() {
    otpController.dispose();
    focusNode.dispose();
    _timer?.cancel();
    super.onClose();
  }
}
