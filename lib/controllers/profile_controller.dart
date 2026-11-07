import 'package:instant_delivery/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/services/api_service.dart';

class ProfileController extends GetxController {
  final ApiService _apiService = ApiService();

  var isLoading = false.obs;
  var user = {}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;

      final response = await _apiService.getProfile();

      if (response.statusCode == 200) {
        user.value = response.data; // ✅ FIX HERE
      } else {
        AppSnackbar.show("Error", "Failed to load profile");
      }

    } catch (e) {
      AppSnackbar.show("Error", "Something went wrong");
      print(e);
    } finally {
      isLoading.value = false;
    }
  }
}