class Cart {
  final List<CartItem> items;
  final double cartTotal;

  Cart({required this.items, required this.cartTotal});

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      cartTotal: (json['cart_total'] as num).toDouble(),
    );
  }
}

class CartItem {
  final int product_id;
  final String product;
  final int quantity;
  final double price;
  final double total; // ← was missing
  final int totalStock; // ← fixed
  final String? image;

  CartItem({
    required this.product_id,
    required this.product,
    required this.quantity,
    required this.price,
    required this.total,
    required this.totalStock, // ← fixed
    this.image,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product_id: json['product_id'],
      product: json['product'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      totalStock: json['total_stock'] ?? 0, // ← fixed, parsed here
      image: json['image'],
    );
  }
}
