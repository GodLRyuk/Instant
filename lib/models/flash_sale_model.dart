import 'package:instant_delivery/models/product_model.dart';

class FlashSaleModel {
  final String title;
  final DateTime endTime;
  final List<ProductModel> products;

  FlashSaleModel({
    required this.title,
    required this.endTime,
    required this.products,
  });
}
