import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

class CategoryController extends GetxController {
  var categoryList = <CategoryModel>[].obs;
  var isLoading = false.obs;

  final ApiService _apiService = ApiService();
  final bool loadOnInit;

  CategoryController({this.loadOnInit = true});

  @override
  void onInit() {
    if (loadOnInit) fetchCategories();
    super.onInit();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading(true);

      final data = await _apiService.getCategory();

      categoryList.value = data;
    } catch (e) {
      // fallback (optional)
      categoryList.value = [
        CategoryModel(id: 1, name: "Food"),
        CategoryModel(id: 2, name: "Grocery"),
      ];
    } finally {
      isLoading(false);
    }
  }
}
