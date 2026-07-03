import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:instant_delivery/config/app_config.dart';

class TrackingService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  Timer? _pingTimer;

  Stream<Map<String, dynamic>>? get stream => _controller?.stream;

  Future<void> connectToOrder(int orderId) async {
    // Close any existing connection before opening a new one
    await disconnect();

    _controller = StreamController<Map<String, dynamic>>.broadcast();

    final wsUrl = '${AppConfig.wsUrl}/ws/order/$orderId/tracking/';

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      await _channel!.ready;

      _channel!.stream.listen(
        (message) {
          if (_controller == null || _controller!.isClosed) return;
          final data = jsonDecode(message as String) as Map<String, dynamic>;
          _controller!.add(data);
        },
        onError: (Object error) {
          _controller?.addError(error);
        },
        onDone: () {
          _controller?.close();
        },
      );

      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        sendPing();
      });
    } catch (e) {
      _controller?.addError(e);
    }
  }

  void sendPing() {
    _channel?.sink.add(jsonEncode({'type': 'ping'}));
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _channel?.sink.close();
    _channel = null;
    await _controller?.close();
    _controller = null;
  }
}
