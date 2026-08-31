import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'otp_controller.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OtpController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Blue Header ──
                  _buildHeader(controller),

                  // ── Body ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step Indicator
                        _buildStepIndicator(),
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Enter Verification Code',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A ${controller.isMsg91 ? "4" : "6"}-digit OTP has been sent to your\nregistered mobile number',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
                        ),
                        const SizedBox(height: 28),

                        // OTP Boxes (Updated to 6)
                        _buildOtpBoxes(controller),
                        const SizedBox(height: 20),

                        // Timer / Resend
                        _buildResendSection(controller),
                        const SizedBox(height: 28),

                        // Verify Button
                        _buildVerifyButton(controller),
                        const SizedBox(height: 12),

                        // Change Number
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Get.back();
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            label: const Text('Change Mobile Number', style: AppTextStyles.btnSecondary),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(OtpController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 70, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.18)),
            child: const Icon(Icons.phone_android_rounded, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 14),
          const Text('OTP Verification', style: AppTextStyles.heading2),
          const SizedBox(height: 5),
          Text('Code sent to +91 ${controller.mobileNumber}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(filled: true),
        _stepLine(filled: true),
        _stepDot(filled: true),
        _stepLine(filled: false),
        _stepDot(filled: false),
      ],
    );
  }

  Widget _stepDot({required bool filled}) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: filled ? AppColors.primary : AppColors.primaryBorder),
    );
  }

  Widget _stepLine({required bool filled}) {
    return Expanded(child: Container(height: 2, color: filled ? AppColors.primary : AppColors.primaryBorder));
  }

  Widget _buildOtpBoxes(OtpController controller) {
    final defaultPinTheme = PinTheme(
      width: controller.isMsg91 ? 56 : 48,
      height: 60,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
      decoration: BoxDecoration(
        color: AppColors.bgWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBorder, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(border: Border.all(color: AppColors.primary, width: 2.5)),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primarySurface,
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
    );

    return Center(
      child: Pinput(
        length: controller.isMsg91 ? 4 : 6,
        controller: controller.otpController,
        focusNode: controller.focusNode,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: submittedPinTheme,
        onChanged: (val) => controller.enteredOtp.value = val,
        onCompleted: (pin) => controller.verifyOtp(pin),
        hapticFeedbackType: HapticFeedbackType.lightImpact,
      ),
    );
  }

  Widget _buildResendSection(OtpController controller) {
    return Obx(
      () => Center(
        child: controller.canResend.value
            ? GestureDetector(
                onTap: controller.resendOtp,
                child: RichText(
                  text: const TextSpan(
                    text: "Didn't receive? ",
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: 'Resend OTP',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              )
            : RichText(
                text: TextSpan(
                  text: 'Resend OTP in ',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  children: [
                    TextSpan(
                      text: controller.timerDisplay,
                      style: const TextStyle(color: Color(0xFFE65100), fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildVerifyButton(OtpController controller) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: controller.isOtpComplete && !controller.isLoading.value ? () => controller.verifyOtp() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            disabledBackgroundColor: AppColors.primaryBorder,
          ),
          child: controller.isLoading.value
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Verify OTP', style: AppTextStyles.btnPrimary),
                  ],
                ),
        ),
      ),
    );
  }
}
