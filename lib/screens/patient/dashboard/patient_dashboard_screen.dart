
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_routes.dart';
import '../../../models/doctor_model.dart';
import '../doctor_search/doctor_search_screen.dart';
import '../appointments/patient_appointments_screen.dart';
import '../patient_profile/patient_profile_screen.dart';
import 'patient_dashboard_controller.dart';

class PatientDashboardScreen extends StatelessWidget {
  const PatientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PatientDashboardController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.bgPage,
          body: Obx(
            () => IndexedStack(
              index: controller.selectedIndex.value,
              children: [
                _buildHomeTab(controller),
                const DoctorSearchScreen(),
                const PatientAppointmentsScreen(),
                const PatientProfileScreen(),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(child: _buildBottomNav(controller)),
        );
      },
    );
  }

  Widget _buildHomeTab(PatientDashboardController controller) {
    return Obx(
      () => controller.isLoading.value
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: controller.onRefresh,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  _buildTopSection(controller),
                  SliverToBoxAdapter(child: _buildSectorSelector(controller)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 50),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Upcoming Appointment Section
                        Obx(() {
                          if (controller.upcomingAppointment.value == null) return const SizedBox.shrink();
                          return Column(children: [const SizedBox(height: 20), _buildUpcomingSection(controller)]);
                        }),

                        const SizedBox(height: 24),
                        _buildQuickActions(), // PRESCRIPTION BUTTON IS HERE
                        const SizedBox(height: 24),
                        _buildSpecializationsSection(controller),
                        const SizedBox(height: 24),
                        _buildTopDoctorsSection(controller),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopSection(PatientDashboardController controller) {
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.primary,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome Back,', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Obx(
                            () => Text(
                              controller.patientName.value.toUpperCase(),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildIconBtn(Icons.notifications_outlined, controller.onNotificationTapped, hasBadge: true),
                    const SizedBox(width: 10),
                    _buildAvatar(controller),
                  ],
                ),
              ),
              _buildSearchBar(controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectorSelector(PatientDashboardController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _sectorChip(controller, 'human', 'Human', Icons.person_rounded),
            _sectorChip(controller, 'veterinary', 'Veterinary', Icons.pets_rounded),
            _sectorChip(controller, 'office', 'Office', Icons.business_rounded),
          ],
        ),
      ),
    );
  }

  Widget _sectorChip(PatientDashboardController controller, String sector, String label, IconData icon) {
    final bool isSelected = controller.currentSector.value == sector;
    return GestureDetector(
      onTap: () => controller.changeSector(sector),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.primaryBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionCard(
                'Prescriptions',
                Icons.description_rounded,
                const Color(0xFFE3F2FD),
                AppColors.primary,
                () => Get.toNamed(AppRoutes.patientRecords),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionCard(
                'Appointments',
                Icons.calendar_month_rounded,
                const Color(0xFFE8F5E9),
                Colors.green,
                () => Get.toNamed(AppRoutes.patientAppointments),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(String title, IconData icon, Color bg, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: AppColors.primaryBorder.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap, {bool hasBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          if (hasBadge)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(PatientDashboardController controller) {
    return GestureDetector(
      onTap: controller.onProfileTapped,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: Center(
          child: Text(
            controller.patientName.value.isNotEmpty ? controller.patientName.value[0].toUpperCase() : 'P',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(PatientDashboardController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: controller.onSearchTapped,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Search doctor, symptom, disease...', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.mic_rounded, color: AppColors.primary, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingSection(PatientDashboardController controller) {
    final appt = controller.upcomingAppointment.value!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.primaryBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Upcoming Appointment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: controller.onViewAllAppointments,
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.doctorName ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(appt.specialization ?? 'Specialist', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _tag(appt.status, const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                  if (appt.tokenNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Token: #${appt.tokenNumber.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${appt.appointmentDate} · ${appt.timeSlot}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                appt.hospitalName ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildSpecializationsSection(PatientDashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Categories', 'See All', controller.onSeeAllDoctors),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: Obx(
            () => ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.specializations.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final bool isActive = controller.selectedSpecIndex.value == -1;
                  return GestureDetector(
                    onTap: () {
                      controller.selectedSpecIndex.value = -1;
                      controller.onSeeAllDoctors();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isActive ? AppColors.primary : AppColors.primaryBorder, width: 1),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                  );
                }

                final spec = controller.specializations[index - 1];
                final bool isActive = controller.selectedSpecIndex.value == index - 1;
                return GestureDetector(
                  onTap: () => controller.onSpecializationTapped(index - 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isActive ? AppColors.primary : AppColors.primaryBorder, width: 1),
                    ),
                    child: Text(
                      spec,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopDoctorsSection(PatientDashboardController controller) {
    return Column(
      children: [
        _sectionHeader('Top Rated Doctors', 'See All', controller.onSeeAllDoctors),
        const SizedBox(height: 12),
        Obx(() {
          if (controller.topDoctors.isEmpty) {
            return const Center(
              child: Text('No doctors available', style: TextStyle(fontSize: 13, color: Colors.grey)),
            );
          }
          return Column(
            children: controller.topDoctors
                .map((doc) => _DoctorCard(doctor: doc, onBook: () => controller.onDoctorBookTapped(doc)))
                .toList(),
          );
        }),
      ],
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: onAction,
          child: Text(
            action,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(PatientDashboardController controller) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_filled, 'Home', controller.selectedIndex.value == 0, () => controller.changeTab(0)),
            _navItem(Icons.calendar_month_rounded, 'Book', controller.selectedIndex.value == 1, () => controller.changeTab(1)),
            _navItem(Icons.assignment_rounded, 'History', controller.selectedIndex.value == 2, () => controller.changeTab(2)),
            _navItem(Icons.person_rounded, 'Profile', controller.selectedIndex.value == 3, () => controller.changeTab(3)),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : Colors.grey.shade400, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppColors.primary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onBook;

  const _DoctorCard({required this.doctor, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBook,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBorder.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(12),
                image: (doctor.photoUrl != null && doctor.photoUrl!.isNotEmpty)
                    ? DecorationImage(image: NetworkImage(doctor.photoUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: (doctor.photoUrl == null || doctor.photoUrl!.isEmpty) ? const Icon(Icons.person, color: Colors.grey, size: 30) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.doctorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    doctor.specialization.join(', '),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      Text(doctor.rating.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.work_history_outlined, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text('${doctor.experience} yrs', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
