import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:instant_delivery/route/app_routes.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/secure_storage.dart';
import 'package:instant_delivery/widgets/navigation/bottom_navigation.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  static AuthController get instance {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController());
    }
    return Get.find<AuthController>();
  }

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var isGuest = false.obs;

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
    isGuest.value = false;

    // offAll clears the route stack — no lingering LoginPage to
    // back-swipe into once the user is authenticated.
    Get.offAll(() => MainNavigation(initialIndex: 2));
  }

  Future<void> continueAsGuest() async {
    await _secureStorage.delete('access_token');
    await _secureStorage.delete('refresh_token');
    isLoggedIn.value = false;
    isGuest.value = true;
    Get.offAll(() => const MainNavigation(initialIndex: 2, isGuest: true));
  }

  /// Resets the in-memory session and clears secure tokens and user data.
  Future<void> logout() async {
    await _secureStorage.delete('access_token');
    await _secureStorage.delete('refresh_token');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token'); // Just in case it was there
    await prefs.remove('refresh_token');
    await prefs.remove('user_id');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('role');
    await prefs.remove('profile_image');

    isLoggedIn.value = false;
    isGuest.value = false;
    Get.offAllNamed(AppRoutes.loginPage);
  }
}
