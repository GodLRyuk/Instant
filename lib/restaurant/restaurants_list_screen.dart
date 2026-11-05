import 'package:flutter/material.dart';
import 'restaurant_cart.dart';
import '../models/restaurant_models.dart';
import '../widgets/restaurant_widgets.dart';

/// Screen 2: all restaurants ("View All" from the home section).
class RestaurantsListScreen extends StatefulWidget {
  const RestaurantsListScreen({
    super.key,
    required this.restaurants,
    required this.cart,
    required this.onOpenRestaurant,
    this.onOpenCart,
    this.onBack,
    this.bannerTitle,
    this.bannerSubtitle,
  });

  final List<Restaurant> restaurants;
  final RestaurantCart cart;
  final ValueChanged<Restaurant> onOpenRestaurant;
  final VoidCallback? onOpenCart;
  final VoidCallback? onBack;
  final String? bannerTitle; // e.g. "30% OFF up to ₹75"
  final String? bannerSubtitle; // e.g. "On your first restaurant order"

  @override
  State<RestaurantsListScreen> createState() => _RestaurantsListScreenState();
}

class _RestaurantsListScreenState extends State<RestaurantsListScreen> {
  String _query = '';
  String _cuisine = 'All';

  List<String> get _cuisines => [
    'All',
    ...{for (final r in widget.restaurants) ...r.cuisines},
  ];

  List<Restaurant> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = widget.restaurants.where((r) {
      final matchQuery =
          q.isEmpty ||
          r.name.toLowerCase().contains(q) ||
          r.cuisines.any((c) => c.toLowerCase().contains(q));
      final matchCuisine = _cuisine == 'All' || r.cuisines.contains(_cuisine);
      return matchQuery && matchCuisine;
    }).toList();
    // Open restaurants first
    list.sort((a, b) => (b.isOpen ? 1 : 0) - (a.isOpen ? 1 : 0));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: RColors.bg,
      body: Column(
        children: [
          RestaurantHeader(
            title: 'Restaurants',
            onBack: widget.onBack,
            trailing: CartBadgeButton(
              cart: widget.cart,
              onTap: widget.onOpenCart,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search restaurants or cuisines',
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: const Icon(Icons.search, color: Colors.orange),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in _cuisines)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: PillChip(
                            label: c,
                            selected: c == _cuisine,
                            onTap: () => setState(() => _cuisine = c),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.bannerTitle != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.bannerTitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (widget.bannerSubtitle != null)
                          Text(
                            widget.bannerSubtitle!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Restaurants near you',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No restaurants found')),
                  ),
                for (final r in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RestaurantTile(
                      restaurant: r,
                      onTap: () => widget.onOpenRestaurant(r),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({required this.restaurant, required this.onTap});

  final Restaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return Opacity(
      opacity: r.isOpen ? 1 : 0.6,
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 104,
                  child: FoodImage(
                    url: r.imageUrl,
                    label: r.cuisines.isEmpty ? '' : r.cuisines.first,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          r.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          r.cuisineText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: RColors.muted,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (r.isOpen)
                          Row(
                            children: [
                              if (r.rating > 0) ...[
                                RatingPill(r.rating),
                                const SizedBox(width: 6),
                              ],
                              Flexible(
                                child: Text(
                                  '${r.etaText} · ${r.distanceKm.toStringAsFixed(1)} km',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF444444),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            r.statusText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF444444),
                            ),
                          ),
                        if (r.isOpen && r.hasOffer) ...[
                          const SizedBox(height: 4),
                          Text(
                            r.offerText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: RColors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
