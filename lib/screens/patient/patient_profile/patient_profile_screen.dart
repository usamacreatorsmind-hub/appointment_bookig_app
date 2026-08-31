import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_routes.dart';
import '../../../utils/helper.dart';
import 'patient_profile_controller.dart';

class PatientProfileScreen extends GetView<PatientProfileController> {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => Get.toNamed(AppRoutes.notifications)),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: controller.goToEditProfile),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = controller.userModel.value;
        final profile = controller.profileModel.value;

        if (user == null) return const Center(child: Text('User not found'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(user),
              const SizedBox(height: 24),

              // Action Cards for Records & Appointments
              _buildActionCard(
                icon: Icons.description_rounded,
                title: 'Medical Records',
                subtitle: 'View your prescriptions',
                onTap: () => Get.toNamed(AppRoutes.patientRecords),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.calendar_month_rounded,
                title: 'Appointment History',
                subtitle: 'Check your visit history',
                onTap: () => Get.toNamed(AppRoutes.patientAppointments),
              ),
              const SizedBox(height: 24),

              // Basic Info Card
              _buildInfoSection('Basic Information', [
                _infoRow(Icons.email_outlined, 'Email', user.email),
                _infoRow(Icons.phone_android_rounded, 'Mobile', user.mobile),
                _infoRow(Icons.calendar_today_rounded, 'DOB', profile?.dob ?? 'Not set'),
                _infoRow(Icons.water_drop_outlined, 'Blood Group', profile?.bloodGroup ?? 'Not set'),
              ]),

              const SizedBox(height: 16),
              _buildMedicalHistory(profile),
              const SizedBox(height: 16),
              _buildInfoSection('Address', [
                _infoRow(Icons.location_on_outlined, 'Address', profile?.address ?? 'Not set'),
                _infoRow(Icons.location_city_rounded, 'City', '${profile?.city ?? ""}, ${profile?.state ?? ""}'),
              ]),

              const SizedBox(height: 24),
              _buildInfoSection('Legal', [
                _actionRow(Icons.privacy_tip_outlined, 'Privacy Policy', LauncherHelper.launchPrivacyPolicy),
                _actionRow(Icons.description_outlined, 'Terms & Conditions', LauncherHelper.launchTermsConditions),
              ]),

              const SizedBox(height: 32),
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.logout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text('Logout', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primarySurface,
          child: Icon(Icons.person, size: 50, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text('Patient ID: ${user.uid.substring(0, 8).toUpperCase()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _actionRow(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistory(dynamic profile) {
    final history = profile?.medicalHistory ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical History',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
          ),
          const Divider(height: 24),
          if (history.isEmpty)
            const Text('No medical history added', style: TextStyle(color: AppColors.textHint, fontSize: 12))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history
                  .map<Widget>(
                    (item) => Chip(
                      label: Text(item, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.bgPage,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
