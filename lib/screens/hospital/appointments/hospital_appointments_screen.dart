import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_routes.dart';
import 'hospital_appointments_controller.dart';
import '../../../models/appointment_model.dart';

class HospitalAppointmentsScreen extends GetView<HospitalAppointmentsController> {
  const HospitalAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => Get.toNamed(AppRoutes.notifications)),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: controller.tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
            Tab(text: 'Missed'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredAppointments.isEmpty) {
                return _buildEmptyState();
              }
              return RefreshIndicator(
                onRefresh: controller.onRefresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.filteredAppointments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildAppointmentCard(controller.filteredAppointments[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          TextField(
            onChanged: controller.onSearch,
            decoration: InputDecoration(
              hintText: 'Search patient or doctor...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.bgPage,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _buildDropdownFilter(
                    value: controller.selectedDoctorId.value.isEmpty ? null : controller.selectedDoctorId.value,
                    hint: 'Filter by Doctor',
                    items: controller.hospitalDoctors
                        .map(
                          (doc) => DropdownMenuItem(
                            value: doc.doctorId,
                            child: Text(doc.doctorName, style: const TextStyle(fontSize: 12)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      controller.selectedDoctorId.value = val ?? '';
                      controller.applyFilters();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _filterChip(
                icon: Icons.calendar_today_rounded,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: Get.context!,
                    initialDate: controller.selectedDate.value ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    controller.selectedDate.value = picked;
                    controller.applyFilters();
                  }
                },
              ),
              const SizedBox(width: 8),
              _filterChip(
                icon: Icons.filter_list_off_rounded,
                onTap: controller.clearFilters,
                color: Colors.red.shade50,
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.bgPage, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          items: items,
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _filterChip({required IconData icon, required VoidCallback onTap, Color? color, Color? iconColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color ?? AppColors.bgPage, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySurface,
                child: const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(appt.patientName ?? 'Patient Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        if (appt.patientType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: appt.patientType == 'New' ? Colors.orange.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              appt.patientType == 'New' ? 'N' : 'O',
                              style: TextStyle(
                                color: appt.patientType == 'New' ? Colors.orange.shade700 : Colors.blue.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        if (appt.tokenNumber != null) ...[
                          Text(
                            '#${appt.tokenNumber.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(appt.appointmentDate, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              _statusBadge(appt.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Dr. ${appt.doctorName ?? 'Doctor'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                appt.timeSlot,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${appt.appointmentId.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                  if (appt.transactionId != null)
                    Text(
                      'TXN: ${appt.transactionId}',
                      style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Mode: ${appt.consultationType}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  Text(
                    appt.paymentStatus == 'Booking Charge Paid' ? 'Online Paid' : appt.paymentStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: appt.paymentStatus == 'Booking Charge Paid' ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey;
    if (status == 'Confirmed') {
      bg = const Color(0xFFE8F5E9);
      text = const Color(0xFF4CAF50);
    } else if (status == 'Pending') {
      bg = const Color(0xFFFFF3E0);
      text = const Color(0xFFFB8C00);
    } else if (status == 'Completed') {
      bg = const Color(0xFFE3F2FD);
      text = const Color(0xFF2196F3);
    } else if (status == 'Cancelled') {
      bg = const Color(0xFFFFEBEE);
      text = const Color(0xFFF44336);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        status,
        style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('No appointments found', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          TextButton(onPressed: controller.clearFilters, child: const Text('Clear all filters')),
        ],
      ),
    );
  }
}
