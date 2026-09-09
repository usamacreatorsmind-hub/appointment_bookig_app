import 'package:get/get.dart';

import '../screens/splash/splash_binding.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/role_selection/role_selection_binding.dart';
import '../screens/role_selection/role_selection_screen.dart';
import '../screens/Login/login_binding.dart';
import '../screens/Login/login_screen.dart';
import '../screens/otp/otp_binding.dart';
import '../screens/otp/otp_screen.dart';
import '../screens/register/register_binding.dart';
import '../screens/register/register_screen.dart';
import '../screens/doctor/register/doctor_register_binding.dart';
import '../screens/doctor/register/doctor_register_screen.dart';
import '../screens/forgot_password/forgot_password_binding.dart';
import '../screens/forgot_password/forgot_password_screen.dart';
import '../screens/patient/profile_setup/profile_setup_binding.dart';
import '../screens/patient/profile_setup/profile_setup_screen.dart';
import '../screens/patient/dashboard/patient_dashboard_binding.dart';
import '../screens/patient/dashboard/patient_dashboard_screen.dart';
import '../screens/patient/doctor_search/doctor_search_binding.dart';
import '../screens/patient/doctor_search/doctor_search_screen.dart';
import '../screens/patient/doctor_profile/doctor_profile_binding.dart';
import '../screens/patient/doctor_profile/doctor_profile_screen.dart';
import '../screens/patient/slot_selection/slot_selection_binding.dart';
import '../screens/patient/slot_selection/slot_selection_screen.dart';
import '../screens/patient/booking_confirm/booking_confirm_binding.dart';
import '../screens/patient/booking_confirm/booking_confirm_screen.dart';
import '../screens/patient/payment/payment_binding.dart';
import '../screens/patient/payment/payment_screen.dart';
import '../screens/patient/booking_success/booking_success_binding.dart';
import '../screens/patient/booking_success/booking_success_screen.dart';
import '../screens/patient/appointments/patient_appointments_binding.dart';
import '../screens/patient/appointments/patient_appointments_screen.dart';
import '../screens/patient/patient_profile/patient_profile_binding.dart';
import '../screens/patient/patient_profile/patient_profile_screen.dart';
import '../screens/patient/records/patient_records_binding.dart';
import '../screens/patient/records/patient_records_screen.dart';
import '../screens/doctor/dashboard/doctor_dashboard_binding.dart';
import '../screens/doctor/dashboard/doctor_dashboard_screen.dart';
import '../screens/doctor/schedule/doctor_schedule_binding.dart';
import '../screens/doctor/schedule/doctor_schedule_screen.dart';
import '../screens/doctor/add_prescription/add_prescription_binding.dart';
import '../screens/doctor/add_prescription/add_prescription_screen.dart';
import '../screens/doctor/reports/doctor_reports_binding.dart';
import '../screens/doctor/reports/doctor_reports_screen.dart';
import '../screens/doctor/profile/doctor_self_profile_binding.dart';
import '../screens/doctor/profile/doctor_self_profile_screen.dart';
import '../screens/doctor/reviews/doctor_reviews_binding.dart';
import '../screens/doctor/reviews/doctor_reviews_screen.dart';
import '../screens/notifications/notifications_binding.dart';
import '../screens/notifications/notifications_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.roleSelection,
      page: () => const RoleSelectionScreen(),
      binding: RoleSelectionBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => const OtpVerificationScreen(),
      binding: OtpBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorRegister,
      page: () => const DoctorRegisterScreen(),
      binding: DoctorRegisterBinding(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupScreen(),
      binding: ProfileSetupBinding(),
    ),
    GetPage(
      name: AppRoutes.patientDashboard,
      page: () => const PatientDashboardScreen(),
      binding: PatientDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorSearch,
      page: () => const DoctorSearchScreen(),
      binding: DoctorSearchBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorProfile,
      page: () => const DoctorProfileScreen(),
      binding: DoctorProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.slotSelection,
      page: () => const SlotSelectionScreen(),
      binding: SlotSelectionBinding(),
    ),
    GetPage(
      name: AppRoutes.bookingConfirm,
      page: () => const BookingConfirmScreen(),
      binding: BookingConfirmBinding(),
    ),
    GetPage(
      name: AppRoutes.payment,
      page: () => const PaymentScreen(),
      binding: PaymentBinding(),
    ),
    GetPage(
      name: AppRoutes.bookingSuccess,
      page: () => const BookingSuccessScreen(),
      binding: BookingSuccessBinding(),
    ),
    GetPage(
      name: AppRoutes.patientAppointments,
      page: () => const PatientAppointmentsScreen(),
      binding: PatientAppointmentsBinding(),
    ),
    GetPage(
      name: AppRoutes.patientProfile,
      page: () => const PatientProfileScreen(),
      binding: PatientProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.patientRecords,
      page: () => const PatientRecordsScreen(),
      binding: PatientRecordsBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorDashboard,
      page: () => const DoctorDashboardScreen(),
      binding: DoctorDashboardBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorSchedule,
      page: () => const DoctorScheduleScreen(),
      binding: DoctorScheduleBinding(),
    ),
    GetPage(
      name: AppRoutes.addPrescription,
      page: () => const AddPrescriptionScreen(),
      binding: AddPrescriptionBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorReports,
      page: () => const DoctorReportsScreen(),
      binding: DoctorReportsBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorSelfProfile,
      page: () => const DoctorSelfProfileScreen(),
      binding: DoctorSelfProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.doctorReviews,
      page: () => const DoctorReviewsScreen(),
      binding: DoctorReviewsBinding(),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
    ),
  ];
}
