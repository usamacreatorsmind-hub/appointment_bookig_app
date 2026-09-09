import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_routes.dart';
import '../../utils/app_images.dart';
import 'login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      builder: (controller) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Get.offAllNamed(AppRoutes.roleSelection);
          },
          child: Scaffold(
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Form: Email/OTP toggle
                        controller.loginWithOtp.value ? _buildOtpForm(controller) : _buildEmailForm(controller),

                        const SizedBox(height: 20),

                        // Divider
                        _buildDivider(controller),
                        const SizedBox(height: 14),

                        // Toggle mode button
                        _buildToggleModeButton(controller),
                        const SizedBox(height: 10),

                        // Register links based on role
                        _buildRegisterSection(controller),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  // ── Blue Header ──
  Widget _buildHeader(LoginController controller) {
    String roleName = 'Account';
    switch (controller.selectedRole.value) {
      case LoginRole.patient:
        roleName = 'Patient';
        break;
      case LoginRole.doctor:
        roleName = 'Doctor';
        break;
      case LoginRole.receptionist:
        roleName = 'Receptionist';
        break;
      case LoginRole.veterinaryDoctor:
        roleName = 'Veterinary Doctor';
        break;
      case LoginRole.petOwner:
        roleName = 'Pet Owner';
        break;
      case LoginRole.officeStaff:
        roleName = 'Office Staff';
        break;
      case LoginRole.visitor:
        roleName = 'Visitor';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 30),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.18)),
            child: ClipOval(
              child: Image.asset(
                AppImages.appLogo,
                fit: BoxFit.cover,
                width: 66,
                height: 66,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Login as $roleName', style: AppTextStyles.heading2),
          const SizedBox(height: 5),
          const Text('Sign in to your account', style: AppTextStyles.body),
        ],
      ),
    );
  }

  // ── Email + Password Form ──
  Widget _buildEmailForm(LoginController controller) {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          // Email
          _buildInputField(
            label: 'Email Address',
            hint: 'Enter your email',
            icon: Icons.mail_outline_rounded,
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            validator: controller.validateEmail,
          ),
          const SizedBox(height: 14),

          // Password
          _buildPasswordField(controller),
          const SizedBox(height: 8),

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: controller.goToForgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Login Button
          _buildPrimaryButton(
            label: 'Login',
            icon: Icons.login_rounded,
            isLoading: controller.isLoading.value,
            onTap: controller.onLoginPressed,
          ),
        ],
      ),
    );
  }

  // ── OTP Form ──
  Widget _buildOtpForm(LoginController controller) {
    return Column(
      children: [
        // Mobile field
        _buildInputField(
          label: 'Mobile Number',
          hint: 'Enter 10-digit mobile number',
          icon: Icons.phone_android_rounded,
          controller: controller.mobileController,
          keyboardType: TextInputType.phone,
          prefix: '+91 ',
        ),
        const SizedBox(height: 20),

        // Send OTP Button
        _buildPrimaryButton(
          label: 'Send OTP',
          icon: Icons.send_rounded,
          isLoading: controller.isLoading.value,
          onTap: controller.onSendOtpPressed,
        ),
      ],
    );
  }

  // ── Divider ──
  Widget _buildDivider(LoginController controller) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.primaryBorder, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            controller.loginWithOtp.value ? 'or login with email' : 'or login with',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(child: Divider(color: AppColors.primaryBorder, thickness: 1)),
      ],
    );
  }

  // ── Toggle Mode Button ──
  Widget _buildToggleModeButton(LoginController controller) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: controller.toggleLoginMode,
        icon: Icon(controller.loginWithOtp.value ? Icons.mail_outline_rounded : Icons.phone_android_rounded, size: 18),
        label: Text(
          controller.loginWithOtp.value ? 'Login with Email & Password' : 'Login with Mobile OTP',
          style: AppTextStyles.btnSecondary,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── Register Section ──
  Widget _buildRegisterSection(LoginController controller) {
    if (controller.selectedRole.value == LoginRole.patient) {
      return _buildRegisterLink('New patient? ', 'Create Account', controller.goToRegister);
    } else if (controller.selectedRole.value == LoginRole.doctor) {
      return _buildRegisterLink('Are you a doctor? ', 'Register Now', () => Get.toNamed(AppRoutes.doctorRegister));
    }
    return const SizedBox.shrink();
  }

  Widget _buildRegisterLink(String text, String actionText, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable Input Field ──
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            prefixText: prefix,
            prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            filled: true,
            fillColor: AppColors.bgWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Password Field ──
  Widget _buildPasswordField(LoginController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller.passwordController,
          obscureText: controller.isPasswordHidden.value,
          validator: controller.validatePassword,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: TextStyle(fontSize: 13, color: AppColors.textHint),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
            suffixIcon: GestureDetector(
              onTap: controller.togglePasswordVisibility,
              child: Icon(
                controller.isPasswordHidden.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: AppColors.bgWhite,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Primary Button ──
  Widget _buildPrimaryButton({required String label, required IconData icon, required bool isLoading, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: AppColors.primaryBorder,
        ),
        child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: AppTextStyles.btnPrimary),
                ],
              ),
      ),
    );
  }
}
