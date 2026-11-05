import 'package:flutter/material.dart';

/// Lightweight, dependency-free skeleton placeholders for content loading.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFE8ECEF),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.itemCount = 6});
  final int itemCount;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: itemCount,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 12,
      childAspectRatio: .62,
    ),
    itemBuilder: (_, _) => const _ProductSkeletonCard(),
  );
}

class _ProductSkeletonCard extends StatelessWidget {
  const _ProductSkeletonCard();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Expanded(child: SkeletonBox(radius: 12)),
      SizedBox(height: 8),
      SkeletonBox(height: 11),
      SizedBox(height: 6),
      SkeletonBox(width: 56, height: 11),
    ],
  );
}

class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({super.key, this.itemCount = 5});
  final int itemCount;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: itemCount,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (_, _) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(children: [
        SkeletonBox(width: 46, height: 46, radius: 24),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(width: 120, height: 13),
          SizedBox(height: 9),
          SkeletonBox(width: 190, height: 11),
        ])),
        SkeletonBox(width: 48, height: 16),
      ]),
    ),
  );
}

class OrderDetailSkeleton extends StatelessWidget {
  const OrderDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: const [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        SkeletonBox(width: 130, height: 20), SkeletonBox(width: 90, height: 14),
      ]),
      SizedBox(height: 20),
      SkeletonBox(height: 110, radius: 14),
      SizedBox(height: 16),
      SkeletonBox(height: 150, radius: 14),
      SizedBox(height: 16),
      SkeletonBox(height: 120, radius: 14),
      SizedBox(height: 16),
      SkeletonBox(height: 170, radius: 14),
    ],
  );
}
