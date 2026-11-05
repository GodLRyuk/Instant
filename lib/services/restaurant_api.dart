import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:instant_delivery/services/log_service.dart';

import '../restaurant/restaurant_cart.dart';
import '../models/restaurant_models.dart';

/// Returns the current JWT access token (or null when logged out).
typedef TokenProvider = Future<String?> Function();

class RestaurantApiException implements Exception {
  RestaurantApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

double _d(dynamic v) => v is num ? v.toDouble() : double.parse(v.toString());

class CuisineInfo {
  const CuisineInfo({required this.id, required this.name});

  final int id;
  final String name;

  factory CuisineInfo.fromJson(Map<String, dynamic> j) =>
      CuisineInfo(id: j['id'] as int, name: j['name'] as String);
}

/// Server-side price of a cart.
class BillQuote {
  const BillQuote({
    required this.itemTotal,
    required this.discount,
    required this.deliveryFee,
    required this.packaging,
    required this.gst,
    required this.total,
  });

  final double itemTotal;
  final double discount;
  final double deliveryFee;
  final double packaging;
  final double gst;
  final double total;

  factory BillQuote.fromJson(Map<String, dynamic> j) => BillQuote(
    itemTotal: _d(j['item_total']),
    discount: _d(j['discount']),
    deliveryFee: _d(j['delivery_fee']),
    packaging: _d(j['packaging_charge']),
    gst: _d(j['gst']),
    total: _d(j['total_amount']),
  );
}

class RazorpayInfo {
  const RazorpayInfo({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.currency,
  });

  final String keyId;
  final String orderId;
  final int amountPaise;
  final String currency;

  factory RazorpayInfo.fromJson(Map<String, dynamic> j) => RazorpayInfo(
    keyId: j['key_id'] as String,
    orderId: j['order_id'] as String,
    amountPaise: (j['amount'] as num).toInt(),
    currency: (j['currency'] ?? 'INR') as String,
  );
}

class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusLabel,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.total,
    required this.restaurantName,
    required this.itemsText,
    this.deliveryOtp,
    this.createdAt,
    this.razorpay,
  });

  final int id;
  final String orderNumber;
  final String
  status; // placed, accepted, preparing, ready, out_for_delivery, delivered ...
  final String statusLabel;
  final String paymentMethod; // online | cod
  final String paymentStatus;
  final double total;
  final String restaurantName;
  final String itemsText; // "1 × Biryani, 2 × Naan"
  final String? deliveryOtp;
  final DateTime? createdAt;
  final RazorpayInfo?
  razorpay; // only on the response of placeOrder() for online payments

  factory PlacedOrder.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List? ?? const [])
        .map((e) => '${(e as Map)['quantity']} × ${e['name']}')
        .join(', ');
    return PlacedOrder(
      id: j['id'] as int,
      orderNumber: j['order_number'] as String,
      status: j['status'] as String,
      statusLabel: j['status_label'] as String,
      paymentMethod: j['payment_method'] as String,
      paymentStatus: j['payment_status'] as String,
      total: _d(j['total_amount']),
      restaurantName: (j['restaurant'] as Map)['name'] as String,
      itemsText: items,
      deliveryOtp: j['delivery_otp']?.toString(),
      createdAt: DateTime.tryParse((j['created_at'] ?? '') as String),
      razorpay: j['razorpay'] == null
          ? null
          : RazorpayInfo.fromJson(j['razorpay'] as Map<String, dynamic>),
    );
  }
}

// ---------------------------------------------------------------- http core
abstract class _ApiClient {
  _ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    this.onUnauthorized,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Example: https://api.instantdelivery.cloud/api
  final String baseUrl;
  final TokenProvider tokenProvider;

  /// Called once when the server answers 401. Refresh your token and return true to retry.
  final Future<bool> Function()? onUnauthorized;
  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  Uri uri(String path, [Map<String, String?>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.isNotEmpty) q[k] = v;
    });
    return Uri.parse(
      '$baseUrl/restaurants/$path',
    ).replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<dynamic> _run(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    var response = await _once(send);
    if (response.statusCode == 401 && onUnauthorized != null) {
      try {
        if (await onUnauthorized!()) response = await _once(send);
      } catch (error, stackTrace) {
        LogService.e(
          'Restaurant API token refresh failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.bodyBytes.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw RestaurantApiException(
      _errorMessage(response),
      statusCode: response.statusCode,
    );
  }

  Future<http.Response> _once(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    final token = await tokenProvider();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    try {
      return await send(headers).timeout(_timeout);
    } on TimeoutException {
      throw RestaurantApiException(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw RestaurantApiException('No internet connection.');
    } on http.ClientException {
      throw RestaurantApiException('Could not reach the server.');
    }
  }

  Future<dynamic> getJson(Uri u) => _run((h) => _client.get(u, headers: h));

  Future<dynamic> sendJson(String method, Uri u, [Object? body]) => _run((h) {
    final headers = {...h, 'Content-Type': 'application/json'};
    final encoded = body == null ? null : jsonEncode(body);
    if (method == 'POST')
      return _client.post(u, headers: headers, body: encoded);
    if (method == 'PATCH')
      return _client.patch(u, headers: headers, body: encoded);
    if (method == 'PUT') return _client.put(u, headers: headers, body: encoded);
    if (method == 'DELETE') return _client.delete(u, headers: headers);
    throw ArgumentError('Unsupported method $method');
  });

  Future<dynamic> sendMultipart(
    String method,
    Uri u, {
    Map<String, String> fields = const {},
    Map<String, File> files = const {},
  }) => _run((h) async {
    final req = http.MultipartRequest(method, u)
      ..headers.addAll(h)
      ..fields.addAll(fields);
    for (final e in files.entries) {
      req.files.add(await http.MultipartFile.fromPath(e.key, e.value.path));
    }
    return http.Response.fromStream(await _client.send(req));
  });

  /// Turns {"items": ["..."]} or {"detail": "..."} into text you can show.
  String _errorMessage(http.Response res) {
    const plainKeys = {
      'detail',
      'non_field_errors',
      'restaurant_id',
      'items',
      'address_id',
      'status',
    };
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map) {
        final parts = <String>[];
        body.forEach((k, v) {
          final text = v is List ? v.join(' ') : v.toString();
          parts.add(plainKeys.contains(k) ? text : '$k: $text');
        });
        if (parts.isNotEmpty) return parts.join('\n');
      }
      if (body is List && body.isNotEmpty) return body.join('\n');
    } catch (_) {}
    if (res.statusCode == 401) return 'Please log in again.';
    if (res.statusCode >= 500) return 'Server error. Please try again.';
    return 'Request failed (${res.statusCode}).';
  }
}

// ---------------------------------------------------------------- customer
class RestaurantApi extends _ApiClient {
  RestaurantApi({
    required super.baseUrl,
    required super.tokenProvider,
    super.onUnauthorized,
    super.client,
  });

  Future<List<CuisineInfo>> cuisines() async {
    final data = await getJson(uri('cuisines/')) as List;
    return data
        .map((e) => CuisineInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Restaurant>> restaurants({
    String? query,
    String? cuisine,
    double? lat,
    double? lng,
  }) async {
    final data =
        await getJson(
              uri('', {
                'q': query,
                'cuisine': cuisine,
                'lat': lat?.toString(),
                'lng': lng?.toString(),
              }),
            )
            as List;
    return data
        .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Restaurant> restaurant(int id, {double? lat, double? lng}) async {
    final data = await getJson(
      uri('$id/', {'lat': lat?.toString(), 'lng': lng?.toString()}),
    );
    return Restaurant.fromJson(data as Map<String, dynamic>);
  }

  Future<List<MenuItem>> menu(int restaurantId) async {
    final data = await getJson(uri('$restaurantId/menu/')) as List;
    return data
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Map<String, int>> _lines(List<CartLine> lines) =>
      lines.map((l) => {'menu_item_id': l.item.id, 'quantity': l.qty}).toList();

  /// The price the server will charge. Use it to double check the cart bill.
  Future<BillQuote> quote({
    required int restaurantId,
    required List<CartLine> lines,
    int? addressId,
  }) async {
    final data = await sendJson('POST', uri('orders/quote/'), {
      'restaurant_id': restaurantId,
      'items': _lines(lines),
      if (addressId != null) 'address_id': addressId,
    });
    return BillQuote.fromJson(data as Map<String, dynamic>);
  }

  /// [paymentMethod] is 'online' or 'cod'. For online, the result has [PlacedOrder.razorpay].
  Future<PlacedOrder> placeOrder({
    required int restaurantId,
    required List<CartLine> lines,
    required int addressId,
    required String paymentMethod,
    String notes = '',
  }) async {
    final data = await sendJson('POST', uri('orders/'), {
      'restaurant_id': restaurantId,
      'items': _lines(lines),
      'address_id': addressId,
      'payment_method': paymentMethod,
      if (notes.isNotEmpty) 'notes': notes,
    });
    return PlacedOrder.fromJson(data as Map<String, dynamic>);
  }

  Future<List<PlacedOrder>> myOrders() async {
    final data = await getJson(uri('orders/')) as List;
    return data
        .map((e) => PlacedOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PlacedOrder> order(int id) async => PlacedOrder.fromJson(
    await getJson(uri('orders/$id/')) as Map<String, dynamic>,
  );

  Future<PlacedOrder> cancelOrder(int id, {String reason = ''}) async =>
      PlacedOrder.fromJson(
        await sendJson('POST', uri('orders/$id/cancel/'), {'reason': reason})
            as Map<String, dynamic>,
      );

  Future<PlacedOrder> verifyPayment({
    required int orderId,
    required String paymentId,
    required String signature,
  }) async => PlacedOrder.fromJson(
    await sendJson('POST', uri('orders/$orderId/verify-payment/'), {
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        })
        as Map<String, dynamic>,
  );
}

// ---------------------------------------------------------------- partner (restaurant owner)
/// For the partner screens (onboarding, menu manager, add dish, orders).
/// Results are plain JSON maps until those screens are built.
class PartnerApi extends _ApiClient {
  PartnerApi({
    required super.baseUrl,
    required super.tokenProvider,
    super.onUnauthorized,
    super.client,
  });

  /// null means this user has not onboarded yet (show the onboarding screen).
  Future<Map<String, dynamic>?> myRestaurant() async {
    try {
      return await getJson(uri('partner/restaurant/')) as Map<String, dynamic>;
    } on RestaurantApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  /// [details] keys: name, phone, address_line, city, fssai_number (required) and
  /// description, email, pincode, latitude, longitude, cuisines (list of ids),
  /// opens_at ("11:00"), closes_at ("23:00"), avg_prep_minutes, offer_* ...
  /// Photos are uploaded in a second request.
  Future<Map<String, dynamic>> onboard(
    Map<String, dynamic> details, {
    File? logo,
    File? cover,
  }) async {
    var result =
        await sendJson('POST', uri('partner/onboard/'), details)
            as Map<String, dynamic>;
    if (logo != null || cover != null) {
      result = await updateRestaurantImages(logo: logo, cover: cover);
    }
    return result;
  }

  Future<Map<String, dynamic>> updateRestaurant(
    Map<String, dynamic> changes,
  ) async =>
      await sendJson('PATCH', uri('partner/restaurant/'), changes)
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> updateRestaurantImages({
    File? logo,
    File? cover,
  }) async =>
      await sendMultipart(
            'PATCH',
            uri('partner/restaurant/'),
            files: {
              if (logo != null) 'logo': logo,
              if (cover != null) 'cover_image': cover,
            },
          )
          as Map<String, dynamic>;

  /// Pause or resume taking orders.
  Future<Map<String, dynamic>> setAcceptingOrders(bool value) =>
      updateRestaurant({'is_accepting_orders': value});

  // categories
  Future<List<Map<String, dynamic>>> categories() async =>
      (await getJson(uri('partner/categories/')) as List)
          .cast<Map<String, dynamic>>();

  Future<Map<String, dynamic>> addCategory(
    String name, {
    int sortOrder = 0,
  }) async =>
      await sendJson('POST', uri('partner/categories/'), {
            'name': name,
            'sort_order': sortOrder,
          })
          as Map<String, dynamic>;

  Future<Map<String, dynamic>> renameCategory(int id, String name) async =>
      await sendJson('PATCH', uri('partner/categories/$id/'), {'name': name})
          as Map<String, dynamic>;

  Future<void> deleteCategory(int id) =>
      sendJson('DELETE', uri('partner/categories/$id/'));

  // dishes
  Future<List<Map<String, dynamic>>> items({int? categoryId}) async =>
      (await getJson(
                uri('partner/items/', {'category': categoryId?.toString()}),
              )
              as List)
          .cast<Map<String, dynamic>>();

  /// [fields]: name, description, category (id), is_veg, price, mrp, packaging_charge,
  /// is_available. The discount percent is worked out by the server from mrp and price.
  Future<Map<String, dynamic>> addItem(
    Map<String, dynamic> fields, {
    File? image,
  }) async {
    final created =
        await sendJson('POST', uri('partner/items/'), fields)
            as Map<String, dynamic>;
    return image == null
        ? created
        : updateItemImage(created['id'] as int, image);
  }

  Future<Map<String, dynamic>> updateItem(
    int id,
    Map<String, dynamic> changes, {
    File? image,
  }) async {
    final updated =
        await sendJson('PATCH', uri('partner/items/$id/'), changes)
            as Map<String, dynamic>;
    return image == null ? updated : updateItemImage(id, image);
  }

  Future<Map<String, dynamic>> updateItemImage(int id, File image) async =>
      await sendMultipart(
            'PATCH',
            uri('partner/items/$id/'),
            files: {'image': image},
          )
          as Map<String, dynamic>;

  Future<void> deleteItem(int id) =>
      sendJson('DELETE', uri('partner/items/$id/'));

  /// In stock / out of stock.
  Future<Map<String, dynamic>> setItemAvailable(int id, bool available) async =>
      await sendJson('POST', uri('partner/items/$id/toggle/'), {
            'is_available': available,
          })
          as Map<String, dynamic>;

  // orders
  Future<List<Map<String, dynamic>>> orders({
    bool activeOnly = true,
    String? status,
  }) async =>
      (await getJson(
                uri('partner/orders/', {
                  'active': activeOnly ? '1' : null,
                  'status': status,
                }),
              )
              as List)
          .cast<Map<String, dynamic>>();

  /// status: accepted | rejected | preparing | ready
  Future<Map<String, dynamic>> setOrderStatus(
    int id,
    String status, {
    String reason = '',
  }) async =>
      await sendJson('POST', uri('partner/orders/$id/status/'), {
            'status': status,
            if (reason.isNotEmpty) 'reason': reason,
          })
          as Map<String, dynamic>;
}
