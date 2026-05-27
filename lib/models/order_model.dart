class OrderModel {
  final String orderNumber;
  final String status;
  final String createdAt;
  final double totalAmount;

  OrderModel({
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.totalAmount,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
    );
  }
}