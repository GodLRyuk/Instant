import 'package:flutter/material.dart';

/// Rupee text: 249 -> "₹249", 12.5 -> "₹12.50".
String rupees(num v) =>
    '₹${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2)}';

class RColors {
  static const green = Color(0xFF2E7D32);
  static const greenLight = Color(0xFF66CC6E);
  static const greenLime = Color(0xFF84C94A);
  static const darkGreen = Color(0xFF0F3D14);
  static const orange = Color(0xFFE65100);
  static const red = Color(0xFFC62828);
  static const bg = Color(0xFFF4F4F4);
  static const text = Color(0xFF222222);
  static const muted = Color(0xFF666666);
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    this.cuisines = const [],
    this.imageUrl,
    this.rating = 0,
    this.ratingCount = 0,
    this.etaMin = 30,
    this.etaMax = 35,
    this.distanceKm = 0,
    this.isOpen = true,
    this.opensAt,
    this.closesAt,
    this.offerPercent,
    this.offerMaxDiscount = 0,
    this.offerCode,
    this.deliveryFee = 0,
  });

  final int id;
  final String name;
  final List<String> cuisines;
  final String? imageUrl;
  final double rating;
  final int ratingCount;
  final int etaMin;
  final int etaMax;
  final double distanceKm;
  final bool isOpen;
  final String? opensAt; // shown when closed, e.g. "11:00 am"
  final String? closesAt; // shown when open, e.g. "11:00 pm"
  final int? offerPercent; // restaurant-wide offer, e.g. 30
  final int offerMaxDiscount; // cap in rupees, e.g. 75
  final String? offerCode;
  final double deliveryFee;

  String get cuisineText => cuisines.join(' · ');
  String get etaText => '$etaMin–$etaMax min';
  bool get hasOffer => offerPercent != null && offerPercent! > 0;
  String get offerText => hasOffer
      ? '$offerPercent% OFF${offerMaxDiscount > 0 ? ' up to ${rupees(offerMaxDiscount)}' : ''}'
      : '';
  String get statusText => isOpen
      ? (closesAt != null ? 'Open until $closesAt' : 'Open')
      : (opensAt != null ? 'Closed · Opens $opensAt' : 'Closed');

  /// Parses the customer-facing restaurant summary returned by the API.
  factory Restaurant.fromJson(Map<String, dynamic> j) {
    final avgPrepMinutes = (j['avg_prep_minutes'] as num?)?.toInt() ?? 30;
    final etaMin =
        (j['eta_min'] as num?)?.toInt() ??
        (j['eta_minutes'] as num?)?.toInt() ??
        avgPrepMinutes;
    final cuisines = j['cuisines'];

    return Restaurant(
      id: j['id'] as int,
      name: j['name'] as String,
      cuisines: cuisines is List
          ? cuisines
                .map(
                  (cuisine) => cuisine is Map
                      ? (cuisine['name'] ?? '').toString()
                      : cuisine.toString(),
                )
                .where((cuisine) => cuisine.isNotEmpty)
                .toList()
          : const [],
      imageUrl: (j['image'] ?? j['cover_image'] ?? j['logo']) as String?,
      rating: (j['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (j['rating_count'] as num?)?.toInt() ?? 0,
      etaMin: etaMin,
      etaMax: (j['eta_max'] as num?)?.toInt() ?? etaMin + 5,
      distanceKm: (j['distance_km'] as num?)?.toDouble() ?? 0,
      isOpen:
          (j['is_open'] as bool?) ??
          (j['is_accepting_orders'] as bool?) ??
          true,
      opensAt: j['opens_at'] as String?,
      closesAt: j['closes_at'] as String?,
      offerPercent: (j['offer_percent'] as num?)?.toInt(),
      offerMaxDiscount: (j['offer_max_discount'] as num?)?.toInt() ?? 0,
      offerCode: j['offer_code'] as String?,
      deliveryFee: (j['delivery_fee'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description = '',
    this.category = 'Recommended',
    this.isVeg = true,
    required this.price,
    this.mrp,
    this.imageUrl,
    this.isAvailable = true,
    this.packagingCharge = 0,
  });

  final int id;
  final int restaurantId;
  final String name;
  final String description;
  final String category;
  final bool isVeg;
  final double price; // selling price
  final double? mrp; // price before discount
  final String? imageUrl;
  final bool isAvailable;
  final double packagingCharge;

  /// 249 selling vs 299 MRP -> 17
  int? get discountPercent => (mrp != null && mrp! > price)
      ? (((mrp! - price) / mrp!) * 100).round()
      : null;

  factory MenuItem.fromJson(Map<String, dynamic> j) {
    final restaurant = j['restaurant'];
    final category = j['category'];

    return MenuItem(
      id: j['id'] as int,
      restaurantId: restaurant is Map
          ? restaurant['id'] as int
          : restaurant as int,
      name: j['name'] as String,
      description: (j['description'] ?? '') as String,
      category: category is Map
          ? (category['name'] ?? 'Recommended') as String
          : category is String
          ? category
          : 'Recommended',
      isVeg: (j['is_veg'] as bool?) ?? true,
      price: double.parse(j['price'].toString()),
      mrp: j['mrp'] == null ? null : double.parse(j['mrp'].toString()),
      imageUrl: j['image'] as String?,
      isAvailable: (j['is_available'] as bool?) ?? true,
      packagingCharge: double.parse((j['packaging_charge'] ?? 0).toString()),
    );
  }
}
