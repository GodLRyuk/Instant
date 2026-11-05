import 'package:flutter/foundation.dart';
import '../models/restaurant_models.dart';

class CartLine {
  CartLine(this.item, this.qty);
  final MenuItem item;
  int qty;
}

/// Bill shown on screen. The server must recalculate it when the order is placed.
class RestaurantBill {
  const RestaurantBill({
    required this.itemTotal,
    required this.discount,
    required this.deliveryFee,
    required this.packaging,
    required this.gst,
  });

  final double itemTotal;
  final double discount;
  final double deliveryFee;
  final double packaging;
  final double gst;

  double get total => itemTotal - discount + deliveryFee + packaging + gst;
}

/// One restaurant per cart. Share ONE instance between the menu and cart screens
/// (Provider, GetIt, a global, or pass it down).
class RestaurantCart extends ChangeNotifier {
  Restaurant? _restaurant;
  final Map<int, CartLine> _lines = {};

  Restaurant? get restaurant => _restaurant;
  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get itemCount => _lines.values.fold(0, (sum, l) => sum + l.qty);
  int qtyOf(int itemId) => _lines[itemId]?.qty ?? 0;

  /// The caller should ask the user first if the cart holds another restaurant.
  void add(Restaurant restaurant, MenuItem item) {
    if (_restaurant?.id != restaurant.id) {
      _lines.clear();
      _restaurant = restaurant;
    }
    final line = _lines[item.id];
    if (line == null) {
      _lines[item.id] = CartLine(item, 1);
    } else {
      line.qty++;
    }
    notifyListeners();
  }

  void increment(MenuItem item) {
    final line = _lines[item.id];
    if (line == null) return;
    line.qty++;
    notifyListeners();
  }

  void decrement(MenuItem item) {
    final line = _lines[item.id];
    if (line == null) return;
    line.qty--;
    if (line.qty <= 0) _lines.remove(item.id);
    if (_lines.isEmpty) _restaurant = null;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _restaurant = null;
    notifyListeners();
  }

  RestaurantBill get bill {
    final r = _restaurant;
    double itemTotal = 0;
    double packaging = 0;
    for (final l in _lines.values) {
      itemTotal += l.item.price * l.qty;
      packaging += l.item.packagingCharge; // once per dish, not per quantity
    }
    double discount = 0;
    if (r != null && r.hasOffer) {
      discount = (itemTotal * r.offerPercent! / 100).roundToDouble();
      if (r.offerMaxDiscount > 0 && discount > r.offerMaxDiscount) {
        discount = r.offerMaxDiscount.toDouble();
      }
    }
    final gst = ((itemTotal - discount) * 0.05).roundToDouble();
    return RestaurantBill(
      itemTotal: itemTotal,
      discount: discount,
      deliveryFee: r?.deliveryFee ?? 0,
      packaging: packaging,
      gst: gst,
    );
  }
}
