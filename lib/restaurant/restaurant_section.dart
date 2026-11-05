import 'package:flutter/material.dart';
import '../models/restaurant_models.dart';

class RestaurantSection extends StatelessWidget {
  final List<Restaurant> restaurants;
  final VoidCallback? onViewAll;
  final ValueChanged<Restaurant>? onTap;

  final String backgroundAsset;

  const RestaurantSection({
    super.key,
    required this.restaurants,
    this.onViewAll,
    this.onTap,
    this.backgroundAsset = 'assets/images/restaurant_bg.png',
  });

  static const _orange = Color(0xFFE65100);

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
      child: Stack(
        children: [
          // Background image (falls back to a gradient)
          Positioned.fill(
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7A2E0B),
                      Color(0xFFC4631C),
                      Color(0xFFE9993E),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Dark overlay so white text stays readable
          Positioned.fill(
            child: ColoredBox(color: Color.fromRGBO(50, 18, 0, 0.45)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(
                  height: 182,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: restaurants.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => _RestaurantCard(
                      restaurant: restaurants[i],
                      onTap: onTap == null
                          ? null
                          : () => onTap!(restaurants[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          const Text(
            'Hungry? Order food',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Text(
                'View All →',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const _RestaurantCard({required this.restaurant, this.onTap});

  static const _green = Color(0xFF2E7D32);
  static const _red = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    final r = restaurant;

    return SizedBox(
      width: 158,
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(r),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (r.rating > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${r.rating.toStringAsFixed(1)} ★',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (r.rating > 0) const SizedBox(width: 6),
                        Text(
                          r.etaText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ],
                    ),
                    if (r.hasOffer) ...[
                      const SizedBox(height: 3),
                      Text(
                        r.offerText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(Restaurant r) {
    final placeholder = Container(
      color: const Color(0xFFB5541B),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(8),
      child: Text(
        (r.cuisines.isEmpty ? '' : r.cuisines.first).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );

    return SizedBox(
      height: 92,
      width: double.infinity,
      child: Stack(
        fit: StackFit.loose,
        children: [
          if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
            Image.network(
              r.imageUrl!,
              fit: BoxFit.fitHeight,
              height: 82,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            )
          else
            placeholder,
          if (!r.isOpen)
            Container(
              color: Color.fromRGBO(0, 0, 0, 0.55),
              alignment: Alignment.center,
              child: const Text(
                'Closed',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
