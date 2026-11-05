import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../services/restaurant_api.dart';
import '../restaurant/restaurant_cart.dart';

class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.label,
    required this.text,
  });

  final int id; // id of the saved address in your addresses API
  final String label; // "Home"
  final String text; // "Flat 4B, Station Road, Asansol"
}

class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// One place to configure the restaurant feature. Call [RestaurantModule.init] once
/// (for example in main() or after login) before opening any restaurant screen.
class RestaurantModule {
  RestaurantModule._();

  static RestaurantApi? _api;
  static PartnerApi? _partnerApi;

  /// One cart for the whole app. One restaurant per cart.
  static final RestaurantCart cart = RestaurantCart();

  static late DeliveryAddress? Function() currentAddress;
  static late Future<DeliveryAddress?> Function(BuildContext context)
  pickAddress;
  static Future<void> Function()? ensureAddressesLoaded;
  static Future<GeoPoint?> Function()? location;
  static String? Function()? prefillContact;
  static String? Function()? prefillEmail;
  static String appName = 'Instant';

  static RestaurantApi get api {
    final a = _api;
    if (a == null) throw StateError('Call RestaurantModule.init() first.');
    return a;
  }

  static PartnerApi get partnerApi {
    final a = _partnerApi;
    if (a == null) throw StateError('Call RestaurantModule.init() first.');
    return a;
  }

  static void init({
    required String baseUrl, // https://api.instantdelivery.cloud/api
    required TokenProvider tokenProvider,
    required DeliveryAddress? Function() currentAddress,
    required Future<DeliveryAddress?> Function(BuildContext context)
    pickAddress,
    Future<void> Function()? ensureAddressesLoaded,
    Future<bool> Function()? onUnauthorized,
    Future<GeoPoint?> Function()? location,
    String? Function()? prefillContact,
    String? Function()? prefillEmail,
    http.Client? client,
  }) {
    _api = RestaurantApi(
      baseUrl: baseUrl,
      tokenProvider: tokenProvider,
      onUnauthorized: onUnauthorized,
      client: client,
    );
    _partnerApi = PartnerApi(
      baseUrl: baseUrl,
      tokenProvider: tokenProvider,
      onUnauthorized: onUnauthorized,
      client: client,
    );
    RestaurantModule.currentAddress = currentAddress;
    RestaurantModule.pickAddress = pickAddress;
    RestaurantModule.ensureAddressesLoaded = ensureAddressesLoaded;
    RestaurantModule.location = location;
    RestaurantModule.prefillContact = prefillContact;
    RestaurantModule.prefillEmail = prefillEmail;
  }
}
