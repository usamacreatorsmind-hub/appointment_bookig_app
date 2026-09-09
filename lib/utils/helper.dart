
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AppSnackBar {
  static void show(String message) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class LauncherHelper {
  static const String privacyPolicyUrl = "https://example.com/privacy-policy";
  static const String termsConditionsUrl = "https://example.com/terms-conditions";

  static Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      AppSnackBar.show('Could not launch $url');
    }
  }

  static void launchPrivacyPolicy() => launchURL(privacyPolicyUrl);
  static void launchTermsConditions() => launchURL(termsConditionsUrl);
}