import 'package:get/get.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/log_service.dart';
import '../models/address_model.dart';

class AddressController extends GetxController {
  var addressList = <AddressModel>[].obs;
  var selectedAddress = Rxn<AddressModel>();
  var isLoading = false.obs;

  final ApiService _apiService = ApiService();

  /// 🔥 FETCH ADDRESSES
  Future<void> fetchAddresses() async {
    try {
      isLoading.value = true;

      final data = await _apiService.getAddresses();

      addressList.value = data;

      /// auto-select default address
      if (data.isNotEmpty) {
        selectedAddress.value = data.firstWhere(
          (a) => a.isDefault,
          orElse: () => data.first,
        );
      }
    } catch (e) {
      LogService.e("Address fetch error", error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addNewAddress({
    required String fullAddress,
    required String city,
    required String state,
    required String pincode,
  }) async {
    try {
      await _apiService.addAddress(
        fullAddress: fullAddress,
        city: city,
        state: state,
        pincode: pincode,
      );

      await fetchAddresses(); // refresh list
    } catch (e) {
      print("Add Address Error: $e");
    }
  }

  /// 🔥 SELECT ADDRESS
  void selectAddress(AddressModel address) {
    selectedAddress.value = address;
  }
}
