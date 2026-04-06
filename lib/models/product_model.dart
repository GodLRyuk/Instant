class ProductModel {
  final int id;
  final String name;
  final String image;
  final double price;
  final double unit_size;
  final String? description;
  final int? categoryId;
  final String? unit_name;
  final double discount_percent;
  final double discounted_price;
  final int? stock;

  ProductModel({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.description,
    this.categoryId,
    required this.unit_size,
    required this.unit_name,
    required this.discount_percent,
    required this.discounted_price,
    required this.stock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      unit_size: double.tryParse(json['unit_size']?.toString() ?? '0') ?? 0.0,
      description: json['description'],
      categoryId: json['category'],
      unit_name: json['unit_name'] ?? '',
      discount_percent:
          double.tryParse(json['discount_percent']?.toString() ?? '0') ?? 0.0,
      discounted_price:
          double.tryParse(json['discounted_price']?.toString() ?? '0') ?? 0.0,
      stock: json['stock'] != null ? int.tryParse(json['stock'].toString()) : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "image": image,
      "price": price,
      "description": description,
      "category": categoryId,
      "unit_size": unit_size,
      "unit_name": unit_name,
      "stock": stock,
    };
  }
}
