import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:instant_delivery/route/app_routes.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/secure_storage.dart';
import 'package:instant_delivery/widgets/navigation/bottom_navigation.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isLoggedIn = false.obs;

  final ApiService _apiService = ApiService();
  final SecureStorage _secureStorage = SecureStorage();

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    final result = await _apiService.login(email, password);
    isLoading.value = false;
    if (result.containsKey('error')) {
      Get.snackbar(
        'Login Failed',
        result['error'],
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _secureStorage.write('saved_email', email);
    await _secureStorage.write('saved_password', password);

    isLoggedIn.value = true;

    // offAll clears the route stack — no lingering LoginPage to
    // back-swipe into once the user is authenticated.
    Get.offAll(() => MainNavigation(initialIndex: 2));
  }

  /// Resets the in-memory session only. Saved biometric credentials in
  /// SecureStorage are intentionally left alone so the fingerprint
  /// button on LoginPage keeps working for quick re-login.
  void logout() {
    isLoggedIn.value = false;
    Get.offAllNamed(AppRoutes.loginPage);
  }
}
