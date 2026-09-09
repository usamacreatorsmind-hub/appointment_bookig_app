import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../../utils/app_images.dart';
import 'role_selection_controller.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RoleSelectionController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                // ── Blue Header ──
                _buildHeader(),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(20),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildRoleCard(
                        controller: controller,
                        role: UserRole.doctor,
                        icon: Icons.medical_services_rounded,
                        iconBgColor: AppColors.doctorBg,
                        iconColor: AppColors.doctorIcon,
                        title: 'Doctor\n(Human)',
                        subtitle: 'Slots & consultations',
                      ),
                      _buildRoleCard(
                        controller: controller,
                        role: UserRole.veterinaryDoctor,
                        icon: Icons.pets_rounded,
                        iconBgColor: AppColors.veterinaryBg,
                        iconColor: AppColors.veterinaryIcon,
                        title: 'Veterinary\nDoctor',
                        subtitle: 'Care for pets',
                      ),
                      _buildRoleCard(
                        controller: controller,
                        role: UserRole.officeStaff,
                        icon: Icons.business_rounded,
                        iconBgColor: AppColors.officeBg,
                        iconColor: AppColors.officeIcon,
                        title: 'Office Staff',
                        subtitle: 'Manage visitors',
                      ),
                      _buildRoleCard(
                        controller: controller,
                        role: UserRole.patient,
                        icon: Icons.person_rounded,
                        iconBgColor: AppColors.patientBg,
                        iconColor: AppColors.patientIcon,
                        title: 'Patient / Pet Owner',
                        subtitle: 'Book appointments',
                      ),
                      _buildRoleCard(
                        controller: controller,
                        role: UserRole.visitor,
                        icon: Icons.badge_rounded,
                        iconBgColor: AppColors.visitorBg,
                        iconColor: AppColors.visitorIcon,
                        title: 'Visitor',
                        subtitle: 'Office visits',
                      ),
                    ],
                  ),
                ),

                // ── Continue Button ──
                _buildFooter(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.18)),
            child: ClipOval(
              child: Image.asset(
                AppImages.appLogo,
                fit: BoxFit.cover,
                width: 50,
                height: 50,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Who are you?', style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          const Text('Select your role to continue', style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required RoleSelectionController controller,
    required UserRole role,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = controller.selectedRole.value == role;

    return GestureDetector(
      onTap: () => controller.selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : AppColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.primaryBorder, width: isSelected ? 2 : 1),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(RoleSelectionController controller) {
    return Obx(() {
      final bool hasSelection = controller.selectedRole.value != null;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: hasSelection ? controller.onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: hasSelection ? AppColors.primary : AppColors.primaryBorder,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Continue', style: AppTextStyles.btnPrimary),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      );
    });
  }
}
