import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../../../models/appointment_model.dart';
import '../../../utils/app_routes.dart';
import 'patient_appointments_controller.dart';
import 'package:intl/intl.dart';
import 'review_dialog.dart';

class PatientAppointmentsScreen extends GetView<PatientAppointmentsController> {
  const PatientAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(
          title: const Text('My Appointments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          elevation: 0,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => Get.toNamed(AppRoutes.notifications)),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              // Upcoming Tab
              _buildAppointmentList(controller.upcomingAppointments, isPast: false),
              // History Tab
              _buildAppointmentList(controller.pastAppointments, isPast: true),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAppointmentList(List<AppointmentModel> appointments, {required bool isPast}) {
    if (appointments.isEmpty) {
      return _buildEmptyState(isPast);
    }

    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appt = appointments[index];
          return _AppointmentCard(
            appointment: appt,
            isPast: isPast,
            onCancel: () => _showCancelDialog(context, appt.appointmentId),
            onReview: () => _showReviewDialog(context, appt),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isPast) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            isPast ? 'No past appointments' : 'No upcoming appointments',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          if (!isPast) TextButton(onPressed: () => Get.back(), child: const Text('Book your first appointment')),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String appointmentId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.cancelAppointment(appointmentId);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context, AppointmentModel appt) async {
    final result = await Get.bottomSheet(
      SafeArea(child: ReviewBottomSheet(appointment: appt)),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    if (result == true) {
      controller.loadAppointments();
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isPast;
  final VoidCallback onCancel;
  final VoidCallback onReview;

  const _AppointmentCard({required this.appointment, required this.isPast, required this.onCancel, required this.onReview});

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bool isMissed =
        isPast &&
        appointment.appointmentDate.compareTo(todayStr) < 0 &&
        (appointment.status == 'Pending' || appointment.status == 'Confirmed');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.medical_services_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appointment.doctorName ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(appointment.specialization ?? 'Specialist', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      appointment.isForSelf
                          ? 'For: Self'
                          : 'For: ${appointment.patientDetails?['name'] ?? 'Someone'} (${appointment.patientDetails?['relationship'] ?? 'Other'})',
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _statusBadge(isMissed ? 'Missed' : appointment.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem(Icons.calendar_today_rounded, appointment.appointmentDate),
              _infoItem(Icons.access_time_rounded, appointment.timeSlot),
              _infoItem(Icons.location_on_rounded, appointment.consultationType),
            ],
          ),
          if (appointment.paymentStatus == 'Booking Charge Paid' || (appointment.bookingCharge ?? 0) > 0) ...[
            const Divider(height: 24, thickness: 0.5),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Slot Fee Paid: ₹${appointment.bookingCharge?.toInt() ?? 0}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const Spacer(),
                if (appointment.transactionId != null)
                  Text(
                    'TXN: ${appointment.transactionId}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Balance to be paid in cash at clinic: ₹${appointment.fee.toInt()}',
              style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
            ),
          ],
          if (!isPast && (appointment.status == 'Pending' || appointment.status == 'Confirmed')) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancel Appointment'),
              ),
            ),
          ],
          if (isPast && appointment.status == 'Completed' && !appointment.isReviewed) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Rate & Review Doctor'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
  Widget _statusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey;

    if (status == 'Confirmed') {
      bg = Colors.green.shade50;
      text = Colors.green;
    } else if (status == 'Pending') {
      bg = Colors.orange.shade50;
      text = Colors.orange;
    } else if (status == 'Cancelled') {
      bg = Colors.red.shade50;
      text = Colors.red;
    } else if (status == 'Missed') {
      bg = Colors.red.shade50;
      text = Colors.red;
    } else if (status == 'Completed') {
      bg = Colors.blue.shade50;
      text = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        status,
        style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
