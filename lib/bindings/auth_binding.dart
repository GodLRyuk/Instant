import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  final bool initialIsLoggedIn;

  AuthBinding({this.initialIsLoggedIn = false});

  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      final authController = AuthController();
      authController.isLoggedIn.value = initialIsLoggedIn;
      Get.put<AuthController>(authController, permanent: true);
    }
  }
}
