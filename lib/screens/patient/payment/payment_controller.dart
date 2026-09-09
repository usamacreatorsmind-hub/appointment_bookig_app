import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../Repository/FirestoreService.dart';
import '../../../models/payment_model.dart';
import '../../../utils/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../utils/helper.dart';

class PaymentController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  late Razorpay _razorpay;

  late String appointmentId;
  late double doctorFee;
  late double bookingFee;
  late String doctorName;
  late String patientName;
  late String date;
  late String time;

  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null &&
        args['appointmentId'] != null &&
        args['amount'] != null &&
        args['doctorName'] != null &&
        args['patientName'] != null &&
        args['date'] != null &&
        args['time'] != null) {
      appointmentId = args['appointmentId'];
      doctorFee = args['amount'];
      bookingFee = args['bookingFee'] ?? 50.0;
      doctorName = args['doctorName'];
      patientName = args['patientName'];
      date = args['date'];
      time = args['time'];
    } else {
      Get.back();
      AppSnackBar.show('Payment details missing');
    }
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  double get totalToPay => bookingFee;

  Future<void> processPayment() async {
    if (_auth.currentUser == null) {
      AppSnackBar.show('User not logged in');
      return;
    }

    isLoading.value = true;
    update();

    try {
      // 1. Create Order on Backend
      final HttpsCallable callable = _functions.httpsCallable('createRazorpayOrder');
      final result = await callable.call({
        'amount': (totalToPay * 100).toInt(), // Convert to Paisa
        'currency': 'INR',
        'appointmentId': appointmentId,
        'patientId': _auth.currentUser!.uid,
      });

      final orderId = result.data['id'];

      // 2. Start Razorpay Flow
      var options = {
        'key': 'rzp_live_TUN2EGCy4mg6kn',
        'amount': (totalToPay * 100).toInt(),
        'name': 'Ayu Veda Care',
        'order_id': orderId,
        'description': 'Slot Booking for Dr. $doctorName',
        'timeout': 300, // in seconds
        'prefill': {
          'contact': _auth.currentUser!.phoneNumber ?? '',
          'email': _auth.currentUser!.email ?? '',
          'name': patientName,
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _razorpay.open(options);
    } catch (e) {
      isLoading.value = false;
      update();
      AppSnackBar.show('Failed to initiate payment: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final payment = PaymentModel(
        paymentId: '',
        appointmentId: appointmentId,
        patientId: _auth.currentUser!.uid,
        amount: totalToPay,
        paymentMethod: 'Razorpay',
        transactionId: response.paymentId ?? '',
        razorpayOrderId: response.orderId,
        razorpaySignature: response.signature,
        paymentDate: DateTime.now().toIso8601String(),
        status: 'Success',
        createdAt: DateTime.now(),
      );

      await _firestoreService.createPayment(payment);

      await _firestoreService.updateAppointment(appointmentId, {
        'status': 'Confirmed',
        'paymentStatus': 'Booking Charge Paid',
        'bookingCharge': bookingFee,
        'transactionId': payment.transactionId,
        'razorpayOrderId': response.orderId,
      });

      isLoading.value = false;
      update();

      AppSnackBar.show('Booking confirmed successfully!');
      Get.offNamed(AppRoutes.bookingSuccess, arguments: {
        'doctorName': doctorName,
        'patientName': patientName,
        'date': date,
        'time': time,
      });
    } catch (e) {
      isLoading.value = false;
      update();
      AppSnackBar.show('Payment successful, but failed to update records: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isLoading.value = false;
    update();
    AppSnackBar.show('Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppSnackBar.show('External wallet selected: ${response.walletName}');
  }
}
