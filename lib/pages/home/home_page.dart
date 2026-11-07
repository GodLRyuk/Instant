import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/bundle_controller.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/address_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/controllers/wishlist_controller.dart';
import 'package:instant_delivery/config/app_config.dart';
import 'package:instant_delivery/models/restaurant_module.dart';
import 'package:instant_delivery/restaurant/restaurant_pages.dart';
import 'package:instant_delivery/pages/product/all_products.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/secure_storage.dart';
import 'package:instant_delivery/widgets/cards/bundle_strip.dart';
import 'package:instant_delivery/widgets/cards/category_card.dart';
import 'package:instant_delivery/widgets/cards/product_card.dart';
import 'package:instant_delivery/widgets/cards/flash_sale_strip.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';
import 'package:instant_delivery/widgets/skeleton_loader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryController categoryController = Get.put(
    CategoryController(loadOnInit: false),
  );

  final ProductController productController = Get.put(
    ProductController(loadOnInit: false),
    tag: "all",
  );
  final ProductController newArrivalController = Get.put(
    ProductController(loadOnInit: false),
    tag: "new",
  );
  final ProductController recommendedController = Get.put(
    ProductController(loadOnInit: false),
    tag: "rec",
  );
  final ProductController searchControllerX = Get.put(
    ProductController(loadOnInit: false),
    tag: "search",
  );
  late PageController _midBannerController;
  final ProductController bannerController = Get.put(
    ProductController(loadOnInit: false),
  );
  final ProductController topBannerController = Get.put(
    ProductController(loadOnInit: false),
  );
  final TextEditingController searchController = TextEditingController();
  final RxList searchResults = [].obs;
  final RxBool showSearchBox = false.obs;
  int _currentPage = 0;
  int _nextLazySection = 0;
  bool _isLoadingInitialSections = true;
  bool _isLoadingNextSection = false;
  Timer? _timer;

  final ProductController flashSaleController = Get.put(
    ProductController(loadOnInit: false),
    tag: "flash",
  );
  final AddressController addressController = Get.put(AddressController());
  final WishlistController wishlistController = Get.put(WishlistController());
  final BundleController bundleController = Get.put(
    BundleController(loadOnInit: false),
  );
  late final Future<void> _addressesLoaded;
  final ScrollController _homeScrollController = ScrollController();

  final List<String> _sectionTitleTemplates = const [
    "{category} temptations await",
    "Discover more {category}",
    "Stock up on {category}",
    "Freshly picked {category}",
    "Top picks in {category}",
    "Everything {category}",
  ];

  final List<String> _sectionSubtitleTemplates = const [
    "Handpicked {category} just for you",
    "Best sellers in {category}",
    "Everything you need in {category}",
    "Loved by our customers",
    "Curated picks, just for you",
  ];

  @override
  void initState() {
    super.initState();

    final storage = SecureStorage();
    final api = ApiService();
    RestaurantModule.init(
      baseUrl: AppConfig.baseUrl,
      tokenProvider: () => storage.read('access_token'),
      currentAddress: () {
        final address = addressController.selectedAddress.value;
        if (address == null) return null;
        return DeliveryAddress(
          id: address.id,
          label: address.isDefault ? 'Default address' : 'Saved address',
          text: address.fullAddress,
        );
      },
      pickAddress: _pickRestaurantAddress,
      ensureAddressesLoaded: _ensureAddressesLoaded,
      onUnauthorized: () async => await api.refreshToken() != null,
    );
    _addressesLoaded = addressController.fetchAddresses();

    _midBannerController = PageController();
    _homeScrollController.addListener(_handleHomeScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialHomeSections();
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_midBannerController.hasClients &&
          bannerController.bannerList.isNotEmpty) {
        _currentPage++;
        if (_currentPage >= bannerController.bannerList.length) {
          _currentPage = 0;
        }
        _midBannerController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _midBannerController.dispose();
    _homeScrollController
      ..removeListener(_handleHomeScroll)
      ..dispose();
    super.dispose();
  }

  void _handleHomeScroll() {
    if (!_homeScrollController.hasClients ||
        _homeScrollController.position.extentAfter > 300 ||
        _isLoadingInitialSections ||
        _isLoadingNextSection) {
      return;
    }

    if (_nextLazySection < 3) {
      _loadNextHomeSection();
      return;
    }

    if (productController.isLoading.value ||
        productController.isMoreLoading.value) {
      return;
    }
    productController.loadMoreProducts();
  }

  Future<void> _loadInitialHomeSections() async {
    try {
      await Future.wait<void>([
        categoryController.fetchCategories(),
        productController.fetchProducts(),
        newArrivalController.fetchNewArrivals(),
        topBannerController.fetchTopBanners(),
      ]);
    } finally {
      _isLoadingInitialSections = false;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleHomeScroll();
        });
      }
    }
  }

  Future<void> _loadNextHomeSection() async {
    if (_isLoadingNextSection || _nextLazySection >= 3) return;
    setState(() => _isLoadingNextSection = true);
    try {
      switch (_nextLazySection) {
        case 0:
          await Future.wait<void>([
            flashSaleController.fetchFlashSale(),
            bundleController.fetchBundles(),
          ]);
          break;
        case 1:
          await recommendedController.fetchRecommended();
          break;
        case 2:
          await bannerController.fetchBanners();
          break;
      }
      _nextLazySection++;
    } catch (error, stackTrace) {
      debugPrint('Unable to load the next home section: $error');
      debugPrintStack(stackTrace: stackTrace);
      // Move on so a failing optional section does not block later sections.
      _nextLazySection++;
    } finally {
      if (mounted) {
        setState(() => _isLoadingNextSection = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleHomeScroll();
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait<void>([
      categoryController.fetchCategories(),
      productController.fetchProducts(),
      newArrivalController.fetchNewArrivals(),
      recommendedController.fetchRecommended(),
      bannerController.fetchBanners(),
      topBannerController.fetchTopBanners(),
      flashSaleController.fetchFlashSale(),
      bundleController.fetchBundles(),
    ]);
    _nextLazySection = 3;
  }

  Future<void> _ensureAddressesLoaded() async {
    await _addressesLoaded;
    if (addressController.addressList.isEmpty) {
      await addressController.fetchAddresses();
    }
  }

  Future<DeliveryAddress?> _pickRestaurantAddress(BuildContext context) async {
    await _ensureAddressesLoaded();
    if (!context.mounted) return null;

    return showModalBottomSheet<DeliveryAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose delivery address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Select where you would like this order delivered.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              Flexible(
                child: Obx(() {
                  final addresses = addressController.addressList;
                  if (addresses.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No saved delivery addresses were found.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final address = addresses[index];
                      final isSelected =
                          addressController.selectedAddress.value?.id ==
                          address.id;
                      final cityLine = [
                        address.city,
                        address.state,
                        address.pincode,
                      ].where((part) => part.trim().isNotEmpty).join(', ');
                      final deliveryAddress = DeliveryAddress(
                        id: address.id,
                        label: address.isDefault
                            ? 'Default address'
                            : 'Saved address',
                        text: address.fullAddress,
                      );

                      return Material(
                        color: isSelected
                            ? const Color(0xFFEAF6EE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            addressController.selectAddress(address);
                            Navigator.of(sheetContext).pop(deliveryAddress);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  address.isDefault
                                      ? Icons.home_outlined
                                      : Icons.location_on_outlined,
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              deliveryAddress.label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (address.isDefault)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF6EE),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'DEFAULT',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(address.fullAddress),
                                      if (cityLine.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          cityLine,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 Icon Mapper
  IconData getIcon(String name) {
    switch (name) {
      case "fastfood":
        return Icons.fastfood;
      case "shopping_cart":
        return Icons.shopping_cart;
      case "apple":
        return Icons.apple;
      case "eco":
        return Icons.eco;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final gridCrossAxisCount = width < 360 ? 2 : 3;
    final gridChildAspectRatio = width < 360
        ? 0.50
        : width < 600
        ? 0.56
        : 0.58;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(title: "Instant", isTransparent: false),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          controller: _homeScrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.015),
              Stack(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    // height: height * 0.06,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        // SizedBox(width: width * 0.03),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: TextField(
                              controller: searchController,
                              textInputAction: TextInputAction.search,

                              // 👇 Keep enter key search
                              onSubmitted: (value) async {
                                await searchControllerX.filterBySearch(value);

                                Get.to(
                                  () => AllProductsPage(
                                    initialProducts: searchControllerX
                                        .productList
                                        .toList(),
                                    pageTitle: 'Search results',
                                  ),
                                );
                              },

                              decoration: InputDecoration(
                                hintText: "Search products...",
                                border: InputBorder.none,

                                // 👇 ADD THIS (right side search icon)
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    final value = searchController.text.trim();

                                    if (value.isNotEmpty) {
                                      await searchControllerX.filterBySearch(
                                        value,
                                      );

                                      Get.to(
                                        () => AllProductsPage(
                                          initialProducts: searchControllerX
                                              .productList
                                              .toList(),
                                          pageTitle: 'Search results',
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.01),
              SizedBox(
                height: height * 0.10,
                child: Obx(() {
                  if (categoryController.isLoading.value) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 6,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (_, _) => const Column(children: [
                        SkeletonBox(width: 58, height: 58, radius: 29),
                        SizedBox(height: 6), SkeletonBox(width: 58, height: 10),
                      ]),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryController.categoryList.length,
                    itemBuilder: (context, index) {
                      final category = categoryController.categoryList[index];

                      return GestureDetector(
                        onTap: () async {
                          // optional: show loading overlay while fetching all
                          await Future.wait([
                            productController.fetchProductsByCategory(
                              category.id.toString(),
                            ),
                            newArrivalController.fetchNewArrivalsByCategory(
                              category.id.toString(),
                            ),
                            recommendedController.fetchRecommendedByCategory(
                              category.id.toString(),
                            ),
                          ]);
                        },
                        child: Container(
                          width: width * 0.2,
                          margin: EdgeInsets.only(left: width * 0.02),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: width * 0.06,
                                backgroundColor: Colors.green.shade50,
                                child: CachedNetworkImage(
                                  imageUrl: category.image ?? '',
                                  width: width * 0.08,
                                  height: width * 0.1,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Icon(
                                    Icons.category,
                                    color: Colors.grey[300],
                                    size: width * 0.07,
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.category,
                                    color: Colors.grey[400],
                                    size: width * 0.07,
                                  ),
                                ),
                              ),
                              // SizedBox(height: height * 0.008),
                              Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: width * 0.03),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),

              const RestaurantHomeSection(),
              SizedBox(height: height * 0.015),
              // 🔥 Products Title
              SectionHeader(
                title: 'New Arrival',
                onViewAll: () => Get.to(
                  () => AllProductsPage(
                    pageTitle: 'New Arrivals',
                    prioritizedProducts: newArrivalController.newArrivalList
                        .toList(),
                  ),
                ),
              ),

              SizedBox(height: height * 0.015),

              // ✅ NEW ARRIVAL — 3-column grid, category-style cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                child: Obx(() {
                  if (newArrivalController.isLoading.value) {
                    return const ProductGridSkeleton();
                  }
                  final newArrival = newArrivalController.newArrivalList;
                  final displayCount = newArrival.length > 6
                      ? 6
                      : newArrival.length;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayCount,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCrossAxisCount,
                      crossAxisSpacing: width * 0.025,
                      mainAxisSpacing: height * 0.015,
                      childAspectRatio: gridChildAspectRatio,
                    ),
                    itemBuilder: (context, index) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(
                          1.0,
                        ), // ignores system font scale
                      ),
                      child: PromoProductCard(
                        product: newArrival[index],
                        wishlistController: wishlistController,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: height * 0.015),
              // 🔥 Banner
              Obx(() {
                if (topBannerController.isLoading.value) {
                  return SizedBox(
                    height: height * 0.2,
                    child: const SkeletonBox(height: 180, radius: 12),
                  );
                }

                // Guard against empty list
                if (topBannerController.topbannerList.isEmpty) {
                  return SizedBox(
                    height: height * 0.2,
                  ); // or a placeholder widget
                }

                final banner = topBannerController.topbannerList[0];

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                  height: height * 0.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.04),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: banner.image,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey.shade200,
                      child: const SkeletonBox(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                );
              }),
              SizedBox(height: height * 0.015),

              FlashSaleStrip(controller: flashSaleController),

              const BundleStrip(),

              SizedBox(height: height * 0.015),
              if (recommendedController.recommendedList.isNotEmpty) ...[
                SectionHeader(
                  title: 'Recommended for you',
                  onViewAll: () => Get.to(
                    () => AllProductsPage(
                      pageTitle: 'Recommended for you',
                      prioritizedProducts: recommendedController.recommendedList
                          .toList(),
                    ),
                  ),
                ),

                SizedBox(height: height * 0.015),

                // 🔥 Horizontal Product List (Different Design)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: Obx(() {
                    if (recommendedController.isLoading.value) {
                      return const ProductGridSkeleton();
                    }
                    final recommended = recommendedController.recommendedList;
                    final displayCount = recommended.length > 6
                        ? 6
                        : recommended.length;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayCount,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCrossAxisCount,
                        crossAxisSpacing: width * 0.025,
                        mainAxisSpacing: height * 0.015,
                        childAspectRatio: gridChildAspectRatio,
                      ),
                      itemBuilder: (context, index) => PromoProductCard(
                        product: recommended[index],
                        wishlistController: wishlistController,
                      ),
                    );
                  }),
                ),
                SizedBox(height: height * 0.02),
              ],
              // 🔥 Sliding Banner
              // 🔥 Sliding Banner
              Obx(() {
                if (bannerController.isLoading.value) {
                  return SizedBox(
                    height: height * 0.18,
                    child: const SkeletonBox(height: 160, radius: 12),
                  );
                }

                return SizedBox(
                  height: height * 0.20,
                  child: PageView.builder(
                    controller: _midBannerController,
                    itemCount: bannerController.bannerList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final banner = bannerController.bannerList[index];
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(width * 0.04),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(width * 0.04),
                          child: CachedNetworkImage(
                            imageUrl: banner.image,
                            fit: BoxFit.fill,
                            placeholder: (context, url) => const Center(
                              child: const SkeletonBox(),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
              SizedBox(height: height * 0.02),
              // 🔥 Featured Products Title
              // ✅ PRODUCTS SECTION — 3-column grid
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────
                  SectionHeader(
                    title: 'Top Picks',
                    onViewAll: () => Get.to(
                      () => AllProductsPage(
                        pageTitle: 'Top Picks',
                        prioritizedProducts: productController.productList
                            .toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.018),

                  // ── 3-column grid ─────────────────────────────
                  Obx(() {
                    if (productController.isLoading.value) {
                      return const ProductGridSkeleton();
                    }

                    final products = productController.productList;
                    final displayCount = products.length > 6
                        ? 6
                        : products.length;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayCount,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCount,
                          crossAxisSpacing: width * 0.025,
                          mainAxisSpacing: height * 0.015,
                          childAspectRatio: gridChildAspectRatio,
                        ),
                        itemBuilder: (context, index) => PromoProductCard(
                          product: products[index],
                          wishlistController: wishlistController,
                        ),
                      ),
                    );
                  }),
                ],
              ),

              SizedBox(height: height * 0.02),

              // ══════════════════════════════════════════════════
              // NEW: Dynamic curated category banner sections
              Obx(() {
                final categories = categoryController.categoryList;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < categories.length; i++)
                      _buildCategorySection(
                        context,
                        width,
                        height,
                        categoryId: categories[i].id.toString(),
                        title:
                            _sectionTitleTemplates[i %
                                    _sectionTitleTemplates.length]
                                .replaceAll('{category}', categories[i].name),
                        subtitle:
                            _sectionSubtitleTemplates[i %
                                    _sectionSubtitleTemplates.length]
                                .replaceAll('{category}', categories[i].name),
                      ),
                  ],
                );
              }),

              Obx(
                () =>
                    _isLoadingNextSection ||
                        productController.isMoreLoading.value
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : const SizedBox(height: 20),
              ),

              // SizedBox(height: height * 0.05),
              // AppFooterBranding(),
            ],
          ),
        ),
      ),
    );
  }

  void onSearchChanged(String value) async {
    if (value.isEmpty) {
      searchResults.clear();
      showSearchBox.value = false;
      return;
    }

    showSearchBox.value = true;

    await searchControllerX.filterBySearch(value);

    searchResults.value = List.from(searchControllerX.productList);
  }

  // ── Curated category banner section builder ─────────────────────
  Widget _buildCategorySection(
    BuildContext context,
    double width,
    double height, {
    required String categoryId,
    required String title,
    required String subtitle,
  }) {
    return Obx(() {
      final products = productController.productList
          .where((p) => p.categoryId.toString() == categoryId)
          .toList();

      if (products.isEmpty) {
        // No products in this category yet — hide the section instead
        // of showing an empty banner.
        return const SizedBox.shrink();
      }

      final display = products.length > 6 ? products.sublist(0, 6) : products;

      return Padding(
        padding: EdgeInsets.only(bottom: height * 0.025),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            SectionHeader(
              title: title,
              subtitle: subtitle,
              onViewAll: () => Get.to(
                () => AllProductsPage(categoryId: categoryId, pageTitle: title),
              ),
            ),

            SizedBox(height: height * 0.012),

            // ── 3-column grid ─────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: display.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: width * 0.025,
                  mainAxisSpacing: height * 0.015,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) => PromoProductCard(
                  product: display[index],
                  wishlistController: wishlistController,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
