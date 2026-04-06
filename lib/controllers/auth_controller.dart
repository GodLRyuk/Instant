import 'package:get/get.dart';
import 'package:instant_delivery/widgets/navigation/bottom_navigation.dart';
import '../services/api_service.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isLoggedIn = false.obs;

  final ApiService _apiService = ApiService(); // ✅ inject the service

  Future<void> login(String email, String password) async {
    isLoading.value = true;

    final result = await _apiService.login(email, password); // ✅ call the API

    isLoading.value = false;

    if (result.containsKey('error')) {
      Get.snackbar('Login Failed', result['error'],
          snackPosition: SnackPosition.BOTTOM);
    } else {
      isLoggedIn.value = true;
      // Save token if returned
      // GetStorage().write('token', result['token']);
     Get.to(() => MainNavigation(initialIndex: 1)); // Profile tab
    }
  }
}