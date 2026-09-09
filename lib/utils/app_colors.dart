import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryLighter = Color(0xFF42A5F5);
  static const Color primarySurface = Color(0xFFE3F0FF);
  static const Color primaryBorder = Color(0xFFD0E4F7);

  static const Color bgPage = Color(0xFFF5F9FF);
  static const Color bgWhite = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7A99);

  static const Color hospitalBg = Color(0xFFE3F0FF);
  static const Color hospitalIcon = Color(0xFF1565C0);
  static const Color doctorBg = Color(0xFFE8F5E9);
  static const Color doctorIcon = Color(0xFF2E7D32);
  static const Color patientBg = Color(0xFFFFF3E0);
  static const Color patientIcon = Color(0xFFE65100);
  static const Color receptionistBg = Color(0xFFF3E5F5);
  static const Color receptionistIcon = Color(0xFF7B1FA2);
  
  static const Color veterinaryBg = Color(0xFFE0F2F1);
  static const Color veterinaryIcon = Color(0xFF00796B);
  static const Color officeBg = Color(0xFFECEFF1);
  static const Color officeIcon = Color(0xFF455A64);
  static const Color visitorBg = Color(0xFFFFFDE7);
  static const Color visitorIcon = Color(0xFFFBC02D);
  
  static const Color textHint = Colors.grey;

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)],
    stops: [0.0, 0.6, 1.0],
  );
}
