class BundleProductModel {
  final int id;
  final String name;
  final double price;
  final String image;

  BundleProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  factory BundleProductModel.fromJson(Map<String, dynamic> json) {
    return BundleProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      image: json['image_url'] ?? '',
    );
  }
}

class BundleModel {
  final int id;
  final String name;
  final String description;
  final String image;
  final double bundlePrice;
  final double originalPrice;
  final double discountPercent;
  final List<BundleProductModel> products;

  BundleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.bundlePrice,
    required this.originalPrice,
    required this.discountPercent,
    required this.products,
  });

  factory BundleModel.fromJson(Map<String, dynamic> json) {
    return BundleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image_url'] ?? '',
      bundlePrice:
          double.tryParse(json['bundle_price']?.toString() ?? '0') ?? 0.0,
      originalPrice:
          double.tryParse(json['original_price']?.toString() ?? '0') ?? 0.0,
      discountPercent:
          double.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0.0,
      products: (json['products'] as List? ?? [])
          .map((e) => BundleProductModel.fromJson(e))
          .toList(),
    );
  }
}
