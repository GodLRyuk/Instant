import 'package:flutter/material.dart';
import 'restaurant_cart.dart';
import '../models/restaurant_models.dart';
import '../widgets/restaurant_widgets.dart';

/// Screen 3: one restaurant with its dishes.
class RestaurantMenuScreen extends StatefulWidget {
  const RestaurantMenuScreen({
    super.key,
    required this.restaurant,
    required this.items,
    required this.cart,
    required this.onViewCart,
  });

  final Restaurant restaurant;
  final List<MenuItem> items;
  final RestaurantCart cart;
  final VoidCallback onViewCart;

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  String _category = 'All';

  Restaurant get _r => widget.restaurant;

  List<String> get _categories => [
    'All',
    ...{for (final i in widget.items) i.category},
  ];

  List<MenuItem> get _visible => widget.items
      .where((i) => _category == 'All' || i.category == _category)
      .toList();

  Future<void> _add(MenuItem item) async {
    if (!_r.isOpen || !item.isAvailable) return;
    final cart = widget.cart;
    if (!cart.isEmpty && cart.restaurant?.id != _r.id) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Start a new cart?'),
          content: Text(
            'Your cart has items from ${cart.restaurant!.name}. '
            'Adding this dish will clear it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start new cart'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    cart.add(_r, item);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: RColors.bg,
      bottomNavigationBar: _buildCartBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Hero
          SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FoodImage(
                  url: _r.imageUrl,
                  label: _r.cuisines.isEmpty ? '' : _r.cuisines.first,
                ),
                Positioned(
                  top: topPad + 10,
                  left: 16,
                  child: RoundIconButton(
                    icon: Icons.arrow_back,
                    label: 'Back',
                    onTap: () => Navigator.maybePop(context),
                  ),
                ),
              ],
            ),
          ),
          // Everything below overlaps the hero by 34 px
          Transform.translate(
            offset: const Offset(0, -34),
            child: Column(
              children: [
                _buildInfoCard(),

                _buildCategoryChips(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      for (final item in _visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _DishCard(
                            item: item,
                            qty: widget.cart.restaurant?.id == _r.id
                                ? widget.cart.qtyOf(item.id)
                                : 0,
                            enabled: _r.isOpen && item.isAvailable,
                            cart: widget.cart,
                            onAdd: () => _add(item),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _r.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            _r.cuisineText,
            style: const TextStyle(fontSize: 13, color: RColors.muted),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              if (_r.rating > 0) RatingPill(_r.rating),
              if (_r.ratingCount > 0)
                Text(
                  '${_r.ratingCount} ratings',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                  ),
                ),
              Text(
                '${_r.etaText} · ${_r.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _r.statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _r.isOpen ? RColors.green : RColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final c in _categories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillChip(
                  label: c,
                  selected: c == _category,
                  onTap: () => setState(() => _category = c),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    return ListenableBuilder(
      listenable: widget.cart,
      builder: (context, _) {
        final cart = widget.cart;
        final inThis = !cart.isEmpty && cart.restaurant?.id == _r.id;
        if (!inThis) return const SizedBox.shrink();
        final n = cart.itemCount;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Material(
              color: RColors.green,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: widget.onViewCart,
                child: SizedBox(
                  height: 60,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$n ${n == 1 ? 'item' : 'items'} · ${rupees(cart.bill.itemTotal)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'View cart →',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DishCard extends StatelessWidget {
  const _DishCard({
    required this.item,
    required this.qty,
    required this.enabled,
    required this.cart,
    required this.onAdd,
  });

  final MenuItem item;
  final int qty;
  final bool enabled;
  final RestaurantCart cart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: item.isAvailable ? 1 : 0.55,
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VegMark(isVeg: item.isVeg),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          rupees(item.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (item.discountPercent != null) ...[
                          Text(
                            rupees(item.mrp!),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF777777),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            '${item.discountPercent}% OFF',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: RColors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: RColors.muted,
                        ),
                      ),
                    ],
                    if (!item.isAvailable)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Currently unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: RColors.red,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: FoodImage(
                          url: item.imageUrl,
                          label: '',
                          color: const Color(0xFFC9722A),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 6,
                      child: Center(
                        child: qty == 0
                            ? Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                elevation: 1,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: enabled ? onAdd : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                      vertical: 7,
                                    ),
                                    child: Text(
                                      'ADD',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: enabled
                                            ? RColors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : QtyStepper(
                                qty: qty,
                                onMinus: () => cart.decrement(item),
                                onPlus: () => cart.increment(item),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
