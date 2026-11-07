import 'package:get/get.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

class CategoryController extends GetxController {
  var categoryList = <CategoryModel>[].obs;
  var isLoading = false.obs;

  final ApiService _apiService = ApiService();
  final bool loadOnInit;
  bool _categoriesLoaded = false;

  CategoryController({this.loadOnInit = true});

  @override
  void onInit() {
    if (loadOnInit) fetchCategories();
    super.onInit();
  }

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    if (_categoriesLoaded && !forceRefresh) return;
    try {
      isLoading(true);

      final data = await _apiService.getCategory();

      categoryList.value = data;
      _categoriesLoaded = true;
    } catch (e) {
      // fallback (optional)
      categoryList.value = [
        CategoryModel(id: 1, name: "Food"),
        CategoryModel(id: 2, name: "Grocery"),
      ];
      _categoriesLoaded = true;
    } finally {
      isLoading(false);
    }
  }
}
