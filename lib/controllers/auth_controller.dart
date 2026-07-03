import 'package:get/get.dart';
import 'package:instant_delivery/services/secure_storage.dart';
import 'package:instant_delivery/widgets/navigation/bottom_navigation.dart';
import '../services/api_service.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isLoggedIn = false.obs;

  final ApiService _apiService = ApiService(); // ✅ inject the service
  final SecureStorage _secureStorage = SecureStorage();

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    final result = await _apiService.login(email, password);
    print("Login Result: $result");
    isLoading.value = false;
    if (result.containsKey('error')) {
      Get.snackbar(
        'Login Failed',
        result['error'],
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    // Save login credentials (IMPORTANT)
    await _secureStorage.write('saved_email', email);
    await _secureStorage.write('saved_password', password);

    isLoggedIn.value = true;

    Get.to(() => MainNavigation(initialIndex: 2));
  }
}
