import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────
// Firestore Path: payments/{paymentId}
// ─────────────────────────────────────────
class PaymentModel {
  final String paymentId;
  final String appointmentId;
  final String patientId;
  final double amount;
  final String paymentMethod; // UPI | Card | Net Banking | Wallet
  final String transactionId; // Gateway transaction ID
  final String? razorpayOrderId;
  final String? razorpaySignature;
  final String paymentDate;
  final String status;        // Success | Failed | Refunded
  final String? refundId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PaymentModel({
    required this.paymentId,
    required this.appointmentId,
    required this.patientId,
    required this.amount,
    required this.paymentMethod,
    required this.transactionId,
    this.razorpayOrderId,
    this.razorpaySignature,
    required this.paymentDate,
    required this.status,
    this.refundId,
    required this.createdAt,
    this.updatedAt,
  });

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      paymentId: id,
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      transactionId: map['transactionId'] ?? '',
      razorpayOrderId: map['razorpayOrderId'],
      razorpaySignature: map['razorpaySignature'],
      paymentDate: map['paymentDate'] ?? '',
      status: map['status'] ?? 'Pending',
      refundId: map['refundId'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTimeNullable(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
      'paymentDate': paymentDate,
      'status': status,
      'refundId': refundId,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
