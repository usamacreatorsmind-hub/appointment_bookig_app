import 'package:doctor_app/utils/app_colors.dart';
import 'package:doctor_app/utils/app_pages.dart' show AppPages;
import 'package:doctor_app/utils/app_routes.dart' show AppRoutes;
import 'package:doctor_app/utils/initial_binding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
    );
    runApp(const AppointmentBookingApp());
  } catch (e) {
    runApp(const AppointmentBookingApp());
  }
}

class AppointmentBookingApp extends StatelessWidget {
  const AppointmentBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GetMaterialApp(
        title: 'Appointment Booking App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: AppColors.primary,
          useMaterial3: true,
          fontFamily: 'Poppins',
          scaffoldBackgroundColor: AppColors.bgPage,
        ),
        initialBinding: InitialBinding(),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.pages,
        defaultTransition: Transition.fade,
      ),
    );
  }
}

