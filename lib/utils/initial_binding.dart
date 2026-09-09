import 'package:get/get.dart';
import 'package:get/get_instance/src/bindings_interface.dart';

import '../services/notification_service.dart';
import '../services/settings_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NotificationService(), permanent: true);
    Get.put(SettingsService(), permanent: true);
  }
}