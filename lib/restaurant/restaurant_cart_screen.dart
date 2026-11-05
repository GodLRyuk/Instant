import 'package:flutter/material.dart';
import 'restaurant_cart.dart';
import '../models/restaurant_models.dart';
import '../widgets/restaurant_widgets.dart';

enum PaymentMethod { online, cod }

/// Screen 4: cart, bill and place order.
class RestaurantCartScreen extends StatefulWidget {
  const RestaurantCartScreen({
    super.key,
    required this.cart,
    required this.addressLabel,
    required this.addressText,
    required this.onPlaceOrder,
    this.onChangeAddress,
    this.onBack,
  });

  final RestaurantCart cart;
  final String addressLabel; // e.g. "Home"
  final String addressText;
  final VoidCallback? onChangeAddress;
  final VoidCallback? onBack;

  /// Call your order API here (and open Razorpay when PaymentMethod.online).
  /// Clear the cart and navigate yourself when it succeeds.
  final Future<void> Function(PaymentMethod method) onPlaceOrder;

  @override
  State<RestaurantCartScreen> createState() => _RestaurantCartScreenState();
}

class _RestaurantCartScreenState extends State<RestaurantCartScreen> {
  PaymentMethod _payment = PaymentMethod.online;
  bool _placing = false;

  Future<void> _place() async {
    setState(() => _placing = true);
    try {
      await widget.onPlaceOrder(_payment);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: ListenableBuilder(
        listenable: widget.cart,
        builder: (context, _) {
          final cart = widget.cart;
          if (cart.isEmpty) {
            return Column(
              children: [
                RestaurantHeader(title: 'Your order', onBack: widget.onBack),
                const Expanded(
                  child: Center(child: Text('Your cart is empty')),
                ),
              ],
            );
          }
          final r = cart.restaurant!;
          final bill = cart.bill;
          return Column(
            children: [
              RestaurantHeader(
                title: 'Your order',
                subtitle: '${r.name} · ${r.etaText}',
                onBack: widget.onBack,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _card(
                      child: Column(
                        children: [
                          for (var i = 0; i < cart.lines.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            _lineRow(cart, cart.lines[i]),
                          ],
                        ],
                      ),
                    ),
                    if (bill.discount > 0) ...[
                      const SizedBox(height: 10),
                      _card(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${r.offerCode ?? 'Offer'} applied',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: RColors.green,
                              ),
                            ),
                            Text(
                              '−${rupees(bill.discount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: RColors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill details',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _billRow('Item total', rupees(bill.itemTotal)),
                          if (bill.discount > 0)
                            _billRow(
                              'Restaurant discount',
                              '−${rupees(bill.discount)}',
                              valueColor: RColors.red,
                            ),
                          _billRow('Delivery fee', rupees(bill.deliveryFee)),
                          if (bill.packaging > 0)
                            _billRow('Packaging', rupees(bill.packaging)),
                          // _billRow('GST', rupees(bill.gst)),
                          const Divider(height: 18),
                          _billRow('To pay', rupees(bill.total), bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Deliver to ${widget.addressLabel}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              InkWell(
                                onTap: widget.onChangeAddress,
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Text(
                                    'Change',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: RColors.green,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.addressText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: RColors.muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              PillChip(
                                label: 'UPI / Card',
                                selected: _payment == PaymentMethod.online,
                                onTap: () => setState(
                                  () => _payment = PaymentMethod.online,
                                ),
                              ),
                              const SizedBox(width: 8),
                              PillChip(
                                label: 'Cash on delivery',
                                selected: _payment == PaymentMethod.cod,
                                onTap: () => setState(
                                  () => _payment = PaymentMethod.cod,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'One restaurant per order. Items from another restaurant start a new cart.',
                      style: TextStyle(fontSize: 12, color: RColors.muted),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _placing || !r.isOpen ? null : _place,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _placing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                r.isOpen
                                    ? 'Place order · ${rupees(bill.total)}'
                                    : 'Restaurant is closed',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );

  Widget _lineRow(RestaurantCart cart, CartLine line) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.item.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${rupees(line.item.price)} each',
                style: const TextStyle(fontSize: 12, color: RColors.muted),
              ),
            ],
          ),
        ),
        QtyStepper(
          filled: false,
          qty: line.qty,
          onMinus: () => cart.decrement(line.item),
          onPlus: () => cart.increment(line.item),
        ),
      ],
    ),
  );

  Widget _billRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: valueColor ?? (bold ? RColors.text : const Color(0xFF444444)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
