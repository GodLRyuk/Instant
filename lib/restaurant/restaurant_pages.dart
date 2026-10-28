import 'package:flutter/material.dart';

import 'razorpay_checkout.dart';
import '../services/restaurant_api.dart';
import 'restaurant_cart_screen.dart';
import 'restaurant_menu_screen.dart';
import '../models/restaurant_models.dart';
import '../models/restaurant_module.dart';
import 'restaurant_section.dart';
import '../widgets/restaurant_widgets.dart';
import 'restaurants_list_screen.dart';
import '../services/log_service.dart';

// ------------------------------------------------------------------ navigation
void openRestaurantsList(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => const RestaurantsListPage()));

void openRestaurantMenu(BuildContext context, Restaurant restaurant) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantMenuPage(restaurant: restaurant),
      ),
    );

void openRestaurantCart(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => const RestaurantCartPage()));

// ------------------------------------------------------------------ home section
/// Drop this on the customer home screen above "New Arrival".
/// It loads restaurants by itself and stays hidden when there is nothing to show.
class RestaurantHomeSection extends StatefulWidget {
  const RestaurantHomeSection({super.key});

  @override
  State<RestaurantHomeSection> createState() => _RestaurantHomeSectionState();
}

class _RestaurantHomeSectionState extends State<RestaurantHomeSection> {
  List<Restaurant> _restaurants = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // final loc = await RestaurantModule.location?.call();
      final list = await RestaurantModule.api.restaurants();
      if (!mounted) return;
      setState(() => _restaurants = list.take(8).toList());
    } catch (error, stackTrace) {
      LogService.e(
        'Could not load restaurants for the home section',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurants.isEmpty) return const SizedBox.shrink();
    return RestaurantSection(
      restaurants: _restaurants,
      onViewAll: () => openRestaurantsList(context),
      onTap: (r) => openRestaurantMenu(context, r),
    );
  }
}

// ------------------------------------------------------------------ screen 2
class RestaurantsListPage extends StatefulWidget {
  const RestaurantsListPage({super.key});

  @override
  State<RestaurantsListPage> createState() => _RestaurantsListPageState();
}

class _RestaurantsListPageState extends State<RestaurantsListPage> {
  late Future<List<Restaurant>> _future = _fetch();

  Future<List<Restaurant>> _fetch() async {
    final loc = await RestaurantModule.location?.call();
    return RestaurantModule.api.restaurants(lat: loc?.lat, lng: loc?.lng);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Restaurant>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _LoadingView(title: 'Restaurants');
        }
        if (snap.hasError) {
          return _ErrorView(
            title: 'Restaurants',
            error: snap.error,
            onRetry: () => setState(() => _future = _fetch()),
          );
        }
        return RestaurantsListScreen(
          restaurants: snap.data!,
          cart: RestaurantModule.cart,
          onOpenRestaurant: (r) => openRestaurantMenu(context, r),
          onOpenCart: () => openRestaurantCart(context),
        );
      },
    );
  }
}

// ------------------------------------------------------------------ screen 3
class RestaurantMenuPage extends StatefulWidget {
  const RestaurantMenuPage({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<RestaurantMenuPage> createState() => _RestaurantMenuPageState();
}

class _RestaurantMenuPageState extends State<RestaurantMenuPage> {
  late Future<List<MenuItem>> _future = RestaurantModule.api.menu(
    widget.restaurant.id,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuItem>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _LoadingView(title: widget.restaurant.name);
        }
        if (snap.hasError) {
          return _ErrorView(
            title: widget.restaurant.name,
            error: snap.error,
            onRetry: () => setState(
              () => _future = RestaurantModule.api.menu(widget.restaurant.id),
            ),
          );
        }
        return RestaurantMenuScreen(
          restaurant: widget.restaurant,
          items: snap.data!,
          cart: RestaurantModule.cart,
          onViewCart: () => openRestaurantCart(context),
        );
      },
    );
  }
}

// ------------------------------------------------------------------ screen 4
class RestaurantCartPage extends StatefulWidget {
  const RestaurantCartPage({super.key});

  @override
  State<RestaurantCartPage> createState() => _RestaurantCartPageState();
}

class _RestaurantCartPageState extends State<RestaurantCartPage> {
  DeliveryAddress? _address = RestaurantModule.currentAddress();

  @override
  void initState() {
    super.initState();
    _loadCurrentAddress();
  }

  Future<void> _loadCurrentAddress() async {
    await RestaurantModule.ensureAddressesLoaded?.call();
    if (!mounted) return;
    setState(() => _address = RestaurantModule.currentAddress());
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeAddress() async {
    final picked = await RestaurantModule.pickAddress(context);
    if (picked != null && mounted) setState(() => _address = picked);
  }

  Future<void> _placeOrder(PaymentMethod method) async {
    final api = RestaurantModule.api;
    final cart = RestaurantModule.cart;
    final restaurant = cart.restaurant;
    if (restaurant == null || cart.isEmpty) return;

    if (_address == null) {
      _toast('Please choose a delivery address.');
      await _changeAddress();
      return;
    }

    try {
      var order = await api.placeOrder(
        restaurantId: restaurant.id,
        lines: cart.lines,
        addressId: _address!.id,
        paymentMethod: method == PaymentMethod.online ? 'online' : 'cod',
      );

      if (method == PaymentMethod.online) {
        final info = order.razorpay;
        if (info == null) {
          _toast('Could not start the payment. Please try again.');
          return;
        }
        final paid = await RazorpayCheckout.pay(
          keyId: info.keyId,
          orderId: info.orderId,
          amountPaise: info.amountPaise,
          name: RestaurantModule.appName,
          description: 'Order ${order.orderNumber}',
          contact: RestaurantModule.prefillContact?.call(),
          email: RestaurantModule.prefillEmail?.call(),
        );
        if (paid == null) {
          // Cancelled or failed: release the unpaid order so it does not hang around.
          try {
            await api.cancelOrder(order.id, reason: 'Payment not completed');
          } catch (_) {}
          _toast('Payment was not completed.');
          return;
        }
        try {
          order = await api.verifyPayment(
            orderId: order.id,
            paymentId: paid.paymentId,
            signature: paid.signature,
          );
        } on RestaurantApiException catch (e) {
          _toast(
            'Payment received but could not be confirmed. Please contact support. (${e.message})',
          );
          return;
        }
      }

      cart.clear();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderPlacedPage(order: order)),
      );
    } on RestaurantApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RestaurantCartScreen(
      cart: RestaurantModule.cart,
      addressLabel: _address?.label ?? 'address',
      addressText: _address?.text ?? 'Tap Change to choose where to deliver',
      onChangeAddress: _changeAddress,
      onPlaceOrder: _placeOrder,
    );
  }
}

// ------------------------------------------------------------------ after ordering
class OrderPlacedPage extends StatelessWidget {
  const OrderPlacedPage({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 88, color: RColors.green),
              const SizedBox(height: 16),
              const Text(
                'Order placed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Order ${order.orderNumber} · ${order.restaurantName}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: RColors.muted),
              ),
              const SizedBox(height: 4),
              Text(
                order.itemsText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: RColors.muted),
              ),
              const SizedBox(height: 12),
              Text(
                '${rupees(order.total)} · ${order.paymentMethod == 'cod' ? 'Pay on delivery' : 'Paid online'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Status: ${order.statusLabel}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (order.deliveryOtp != null &&
                  order.deliveryOtp!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Delivery OTP',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.deliveryOtp!.trim(),
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share this code with your delivery partner to confirm delivery.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Back to home',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ small helpers
class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: Column(
        children: [
          RestaurantHeader(title: title),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: Column(
        children: [
          RestaurantHeader(title: title),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error is RestaurantApiException
                          ? (error as RestaurantApiException).message
                          : 'Something went wrong.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
