import 'package:flutter/material.dart';

class AppColors {
  // ── Primary (Brand) ──
  static const Color primary = Color(0xFF2B2560);
  static const Color primaryDark = Color(0xFF1B1740);
  static const Color primarySurface = Color(0xFFF0EEFB); // Light tint of primary
  
  // ── Accent (Action) ──
  static const Color accent = Color(0xFFE8623A);
  static const Color accentLight = Color(0xFFFF8A65);

  // ── Background & Surface ──
  static const Color bgPage = Color(0xFFF7F6FC);
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1E1B33);
  static const Color textSecondary = Color(0xFF6E698F);
  static const Color textHint = Color(0xFF6E698F);

  // ── Border & Divider ──
  static const Color primaryBorder = Color(0xFFE3E0F5);
  static const Color divider = Color(0xFFE3E0F5);

  // ── Feedback ──
  static const Color success = Color(0xFF2E9E5B);
  static const Color warning = Color(0xFFE8A93A);
  static const Color error = Color(0xFFE24C4C);
  static const Color info = Color(0xFF4E7FD9);

  // ── Role Specific (Aligned with new theme) ──
  static const Color doctorBg = Color(0xFFE8F5E9);
  static const Color doctorIcon = Color(0xFF2E9E5B); // Using success green
  static const Color patientBg = Color(0xFFFFF3E0);
  static const Color patientIcon = Color(0xFFE8623A); // Using accent coral
  static const Color veterinaryBg = Color(0xFFE0F2F1);
  static const Color veterinaryIcon = Color(0xFF00796B);
  static const Color officeBg = Color(0xFFECEFF1);
  static const Color officeIcon = Color(0xFF455A64);
  static const Color visitorBg = Color(0xFFFFFDE7);
  static const Color visitorIcon = Color(0xFFE8A93A); // Using warning amber

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B2560), Color(0xFF1B1740)],
  );
}
