import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import 'FirestoreService.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign In with Email/Password
  Future<UserCredential?> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Create Auth account only (used when custom profile creation is needed)
  Future<UserCredential?> signUpAuth(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with Email/Password and Save to Firestore (General)
  Future<UserCredential?> signUp(UserModel user, String password) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: user.email,
      password: password,
    );
    
    if (credential.user != null) {
      // User create hone ke baad Firestore mein save karein
      UserModel newUser = user.copyWith(uid: credential.user!.uid);
      await _firestoreService.createUser(newUser);
    }
    return credential;
  }

  // Phone Verification (OTP)
  Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$phoneNumber', // Indian format as default
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // Verify OTP and Sign In
  Future<UserCredential> signInWithOtp(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Get User Data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    return await _firestoreService.getUser(uid);
  }

  // Get User Data by Email (For script users migration)
  Future<UserModel?> getUserByEmail(String email) async {
    return await _firestoreService.getUserByEmail(email);
  }

  // Get User Data by Mobile
  Future<UserModel?> getUserByMobile(String mobile) async {
    return await _firestoreService.getUserByMobile(mobile);
  }

  // MSG91 Send OTP
  Future<void> sendMsg91Otp(String mobile) async {
    final functions = FirebaseFunctions.instance;
    final HttpsCallable callable = functions.httpsCallable('sendMsg91Otp');
    String formattedMobile = _formatMobileForMsg91(mobile);
    await callable.call({'mobile': formattedMobile});
  }

  // MSG91 Verify OTP
  Future<Map<String, dynamic>> verifyMsg91Otp(String mobile, String otp) async {
    final functions = FirebaseFunctions.instance;
    final HttpsCallable callable = functions.httpsCallable('verifyMsg91Otp');
    String formattedMobile = _formatMobileForMsg91(mobile);
    final result = await callable.call({'mobile': formattedMobile, 'otp': otp.trim()});
    return Map<String, dynamic>.from(result.data);
  }

  String _formatMobileForMsg91(String mobile) {
    // Remove all non-digits
    String digits = mobile.replaceAll(RegExp(r'\D'), '');
    
    // If it's already 12 digits starting with 91, don't add it again
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }
    
    // If it's 10 digits, add 91
    if (digits.length == 10) {
      return '91$digits';
    }
    
    return digits;
  }

  // Sign In with Custom Token
  Future<UserCredential> signInWithCustomToken(String token) async {
    return await _auth.signInWithCustomToken(token);
  }

  // Migrate user record to Auth UID
  Future<void> migrateUser(String oldId, UserModel user) async {
    await _firestoreService.migrateUserToUid(oldId, user);
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
