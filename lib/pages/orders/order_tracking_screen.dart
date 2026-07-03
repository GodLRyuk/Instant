import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:instant_delivery/services/tracking_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  final double? initialLat;
  final double? initialLng;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final TrackingService _trackingService = TrackingService();
  GoogleMapController? _mapController;

  LatLng? _driverLocation;
  String _orderStatus = 'PENDING';
  final Set<Marker> _markers = {};

  String _wsStatus = 'Not connected';
  final List<String> _wsLogs = [];
  bool _showDebug = true;

  // ✅ No context needed — just DateTime
  void _log(String msg) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final entry = '[$time] $msg';
    debugPrint('[WS] $msg');
    // ✅ Safe to call setState only if mounted; during initState, just add to list
    if (mounted) {
      setState(() {
        _wsLogs.insert(0, entry);
        if (_wsLogs.length > 30) _wsLogs.removeLast();
      });
    } else {
      _wsLogs.insert(0, entry);
      if (_wsLogs.length > 30) _wsLogs.removeLast();
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialLat != null && widget.initialLng != null) {
      _driverLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _addDriverMarker(_driverLocation!);
      _log('Initial coords: ${widget.initialLat}, ${widget.initialLng}');
    } else {
      _log('No initial coords passed');
    }

    // ✅ Defer WS connect to after first frame so context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectTracking();
    });
  }

  Future<void> _connectTracking() async {
    _log('Connecting to WS for order #${widget.orderId}...');
    if (mounted) setState(() => _wsStatus = 'Connecting…');

    try {
      await _trackingService.connectToOrder(widget.orderId);

      if (!mounted) return;
      setState(() => _wsStatus = 'Connected ✅');
      _log('WS connected');

      final stream = _trackingService.stream;
      if (stream == null) {
        _log('❌ stream is NULL after connect');
        if (mounted) setState(() => _wsStatus = 'Error: stream is null');
        return;
      }

      stream.listen(
        (data) {
          if (!mounted) return;
          _log('Received: $data');
          final type = data['type'];

          if (type == 'driver_location') {
            final lat = double.tryParse(data['lat'].toString());
            final lng = double.tryParse(data['lng'].toString());
            if (lat != null && lng != null) {
              _log('Driver at: $lat, $lng');
              final pos = LatLng(lat, lng);
              setState(() {
                _driverLocation = pos;
                _addDriverMarker(pos);
              });
              _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
            } else {
              _log('❌ Bad lat/lng values: ${data['lat']}, ${data['lng']}');
            }
          } else if (type == 'order_status') {
            final s = data['status'] as String? ?? '';
            _log('Status update: $s');
            setState(() => _orderStatus = s);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_getStatusMessage(s))));
          } else if (type == 'ping' || type == 'pong') {
            _log('ping/pong received');
          } else {
            _log('Unknown type "$type": $data');
          }
        },
        onError: (Object e) {
          _log('❌ Stream error: $e');
          if (!mounted) return;
          setState(() => _wsStatus = 'Error: $e');
        },
        onDone: () {
          _log('WS closed (onDone)');
          if (!mounted) return;
          setState(() => _wsStatus = 'Disconnected');
        },
      );
    } catch (e, st) {
      _log('❌ Connect exception: $e\n$st');
      if (!mounted) return;
      setState(() => _wsStatus = 'Failed: $e');
    }
  }

  void _addDriverMarker(LatLng position) {
    _markers
      ..removeWhere((m) => m.markerId.value == 'driver')
      ..add(
        Marker(
          markerId: const MarkerId('driver'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Driver'),
        ),
      );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'CONFIRMED':
        return '✅ Order confirmed!';
      case 'PREPARING':
        return '👨‍🍳 Being prepared';
      case 'SHIPPED':
        return '🚚 Driver on the way!';
      case 'DELIVERED':
        return '🎉 Delivered!';
      case 'CANCELLED':
        return '❌ Cancelled';
      default:
        return status.isEmpty ? 'Pending' : status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      case 'SHIPPED':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  void dispose() {
    _trackingService.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order #${widget.orderId}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showDebug ? Icons.bug_report : Icons.bug_report_outlined,
            ),
            onPressed: () => setState(() => _showDebug = !_showDebug),
          ),
        ],
      ),
      body: Column(
        children: [
          // WS connection status bar
          Container(
            width: double.infinity,
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'WS: $_wsStatus',
              style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
            ),
          ),
          // Order status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: _getStatusColor(_orderStatus).withOpacity(0.1),
            child: Text(
              _getStatusMessage(_orderStatus),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _getStatusColor(_orderStatus),
              ),
            ),
          ),
          Expanded(child: _showDebug ? _buildDebugPanel() : _buildMapArea()),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: _OrderStatusTimeline(currentStatus: _orderStatus),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'WebSocket Debug Log',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showDebug = false),
                child: const Text(
                  'Show Map',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
          Text(
            'Order: ${widget.orderId}  |  Driver: ${_driverLocation != null ? "${_driverLocation!.latitude.toStringAsFixed(4)}, ${_driverLocation!.longitude.toStringAsFixed(4)}" : "none"}',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: _wsLogs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet…',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    itemCount: _wsLogs.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _wsLogs[i],
                        style: TextStyle(
                          color: _wsLogs[i].contains('❌')
                              ? Colors.redAccent
                              : Colors.white70,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.greenAccent),
              ),
              onPressed: () {
                _trackingService.sendPing();
                _log('Manual ping sent');
              },
              child: const Text(
                'Send Ping',
                style: TextStyle(color: Colors.greenAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    if (_driverLocation != null) {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _driverLocation!,
          zoom: 15,
        ),
        markers: _markers,
        onMapCreated: (c) => _mapController = c,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Waiting for driver location…'),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => setState(() => _showDebug = true),
            icon: const Icon(Icons.bug_report),
            label: const Text('Show Debug Logs'),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;
  const _OrderStatusTimeline({required this.currentStatus});

  static const _steps = [
    {'status': 'PENDING', 'label': 'Order Placed', 'icon': '📦'},
    {'status': 'CONFIRMED', 'label': 'Confirmed', 'icon': '✅'},
    {'status': 'PREPARING', 'label': 'Preparing', 'icon': '👨‍🍳'},
    {'status': 'SHIPPED', 'label': 'On the way', 'icon': '🚚'},
    {'status': 'DELIVERED', 'label': 'Delivered', 'icon': '🎉'},
  ];
  static const _order = [
    'PENDING',
    'CONFIRMED',
    'PREPARING',
    'SHIPPED',
    'DELIVERED',
  ];

  bool _isCompleted(String s) =>
      _order.indexOf(s) <= _order.indexOf(currentStatus);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _steps.map((step) {
        final done = _isCompleted(step['status']!);
        return Expanded(
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? Colors.green : Colors.grey.shade200,
                ),
                child: Center(
                  child: Text(
                    step['icon']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step['label']!,
                style: TextStyle(
                  fontSize: 10,
                  color: done ? Colors.green : Colors.grey,
                  fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
