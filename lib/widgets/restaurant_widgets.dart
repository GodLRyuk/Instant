import 'package:flutter/material.dart';
import '../restaurant/restaurant_cart.dart';
import '../models/restaurant_models.dart';

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromRGBO(255, 255, 255, 0.85),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Tooltip(
            message: label,
            child: Icon(icon, color: RColors.darkGreen, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Green gradient header with a back button, used on every restaurant screen.
class RestaurantHeader extends StatelessWidget {
  const RestaurantHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [RColors.greenLight, RColors.greenLime],
        ),
      ),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back,
            label: 'Back',
            onTap: onBack ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: RColors.darkGreen,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF14451A),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Cart icon with a live item-count badge.
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key, required this.cart, this.onTap});

  final RestaurantCart cart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final n = cart.itemCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            RoundIconButton(
              icon: Icons.shopping_cart_outlined,
              label: 'Cart',
              onTap: onTap,
            ),
            if (n > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: RColors.orange,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    '$n',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? RColors.green : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? RColors.green : const Color(0xFFE0E0E0),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
}

class RatingPill extends StatelessWidget {
  const RatingPill(this.rating, {super.key});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: RColors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${rating.toStringAsFixed(1)} ★',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class VegMark extends StatelessWidget {
  const VegMark({super.key, required this.isVeg});

  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    final c = isVeg ? RColors.green : RColors.red;
    return Semantics(
      label: isVeg ? 'Veg' : 'Non-veg',
      child: Container(
        width: 14,
        height: 14,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: c, width: 2)),
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// Network image with a coloured placeholder showing [label].
class FoodImage extends StatelessWidget {
  const FoodImage({
    super.key,
    this.url,
    required this.label,
    this.color = const Color(0xFFB5541B),
  });

  final String? url;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: color,
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    this.filled = true,
  });

  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final bool filled; // true: green fill (menu), false: outlined (cart)

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : RColors.green;
    Widget btn(IconData icon, String tip, VoidCallback tap) => InkWell(
      onTap: tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Tooltip(
          message: tip,
          child: Icon(icon, size: 18, color: fg),
        ),
      ),
    );
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: filled ? RColors.green : Colors.white,
        border: filled ? null : Border.all(color: RColors.green),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, 'Remove one', onMinus),
          SizedBox(
            width: 20,
            child: Center(
              child: Text(
                '$qty',
                style: TextStyle(color: fg, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          btn(Icons.add, 'Add one', onPlus),
        ],
      ),
    );
  }
}
