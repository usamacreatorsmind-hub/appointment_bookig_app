import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../models/appointment_model.dart';
import '../../../utils/helper.dart';

class DoctorReportsController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final isLoading = true.obs;
  final totalAppointments = 0.obs;
  final completedAppointments = 0.obs;
  final onlineEarnings = 0.0.obs; // Razorpay (Slot Booking)
  final cashEarnings = 0.0.obs;   // Expected/Collected Cash
  final totalEarnings = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    calculateReports();
  }

  Future<void> calculateReports() async {
    final user = _auth.currentUser;
    if (user == null) return;

    isLoading.value = true;
    update();

    try {
      final doctor = await _firestoreService.getDoctorByUid(user.uid);
      if (doctor != null) {
        // ✅ Fixed: Added 'date:' named parameter
        final allAppts = await _firestoreService.getDoctorAppointments(doctor.doctorId, date: null);
        
        totalAppointments.value = allAppts.length;
        completedAppointments.value = allAppts.where((a) => a.status == 'Completed').length;

        double online = 0;
        double cash = 0;

        for (var a in allAppts) {
          // 1. Online Revenue (from all confirmed/completed bookings)
          if (a.paymentStatus == 'Booking Charge Paid' || a.paymentStatus == 'Paid' || a.paymentStatus == 'Success') {
            online += a.bookingCharge ?? 0;
          }

          // 2. Cash Revenue (only for completed ones)
          if (a.status == 'Completed' && (a.paymentStatus == 'Paid' || a.paymentStatus == 'Success')) {
            cash += a.fee;
          }
        }

        onlineEarnings.value = online;
        cashEarnings.value = cash;
        totalEarnings.value = online + cash;
      }
    } catch (e) {
      AppSnackBar.show('Failed to calculate reports: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
