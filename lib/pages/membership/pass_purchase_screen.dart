import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/pass_controller.dart';
import 'package:instant_delivery/controllers/pass_payment_controller.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class PassPurchasePage extends StatefulWidget {
  const PassPurchasePage({super.key});

  @override
  State<PassPurchasePage> createState() => _PassPurchasePageState();
}

class _PassPurchasePageState extends State<PassPurchasePage> {
  final PassController passController = Get.put(PassController());
  final PassPaymentController passPaymentController = Get.put(
    PassPaymentController(),
  );

  String selectedPlan = "MONTHLY";

  final plans = [
    {
      "type": "MONTHLY",
      "label": "1 Month",
      "price": "₹99",
      "duration": "30 days",
      "cap": "8 free deliveries/month", // ← add
      "tag": null,
      "saving": null,
    },
    {
      "type": "YEARLY",
      "label": "1 Year",
      "price": "₹699",
      "duration": "365 days",
      "cap": "20 free deliveries/month", // ← add
      "tag": "BEST VALUE",
      "saving": "Save ₹489",
    },
  ];

  final monthlyBenefits = [
    {
      "icon": Icons.delivery_dining,
      "text": "Free delivery on orders above ₹149",
    },
    {"icon": Icons.local_offer, "text": "Exclusive member-only coupons"},
    {"icon": Icons.lock_open, "text": "Coupons unlock on orders above ₹299"},
    {"icon": Icons.refresh, "text": "Up to 20 free deliveries/month"},
    {"icon": Icons.calendar_month, "text": "Valid for 30 days"},
  ];

  final yearlyBenefits = [
    {
      "icon": Icons.delivery_dining,
      "text": "Free delivery on orders above ₹149",
    },
    {"icon": Icons.local_offer, "text": "Exclusive member-only coupons"},
    {"icon": Icons.lock_open, "text": "Coupons unlock on orders above ₹299"},
    {"icon": Icons.refresh, "text": "Up to 20 free deliveries/month"},
    {"icon": Icons.calendar_today, "text": "Valid for 365 days"},
    {"icon": Icons.savings, "text": "Save ₹489 vs monthly plan"},
    {"icon": Icons.star, "text": "Priority customer support"},
  ];

  List<Map<String, dynamic>> get currentBenefits =>
      (selectedPlan == "MONTHLY" ? monthlyBenefits : yearlyBenefits)
          .cast<Map<String, dynamic>>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const CustomAppBar(
        title: "Delivery Pass",
        isTransparent: false,
        showBackButton: true,
      ),
      body: Obx(() {
        // ── Loading ───────────────────────────────────────────
        if (passController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // ── Active Pass UI ────────────────────────────────────
        if (passController.hasPass.value) {
          return _buildActivePassUI();
        }

        // ── Purchase UI ───────────────────────────────────────
        return _buildPurchaseUI();
      }),
    );
  }

  // ── ACTIVE PASS UI ──────────────────────────────────────────
  Widget _buildActivePassUI() {
    final cap = passController.freeDeliveryCap.value;
    final remaining = passController.freeDeliveriesRemaining.value;
    final used = cap - remaining;
    final progress = cap > 0 ? remaining / cap : 0.0;
    final isMonthly = passController.planType.value == "MONTHLY";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── ACTIVE HERO CARD ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      "${isMonthly ? 'Monthly' : 'Yearly'} Pass Active",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "ACTIVE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Valid until
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Valid until ${passController.validUntil.value}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── FREE DELIVERIES COUNTER ─────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Free Deliveries This Month",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Big number display
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$remaining",
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: remaining > (cap * 0.3).round()
                            ? Colors.green
                            : remaining > 0
                            ? Colors.orange
                            : Colors.red,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 4),
                      child: Text(
                        " / $cap remaining",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      remaining > 5
                          ? Colors.green
                          : remaining > 0
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  used == 0
                      ? "You haven't used any free deliveries yet"
                      : "$used free ${used == 1 ? 'delivery' : 'deliveries'} used this month",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

                if (remaining == 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Free deliveries reset on the 1st of next month",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── ACTIVE BENEFITS ─────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your Benefits",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                _activeBenefitRow(
                  Icons.delivery_dining,
                  "Free delivery above ₹149",
                ),
                _activeBenefitRow(
                  Icons.local_offer,
                  "Exclusive member coupons",
                ),
                _activeBenefitRow(Icons.lock_open, "Coupons unlock at ₹299+"),
                _activeBenefitRow(Icons.refresh, "$cap free deliveries/month"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── PLAN INFO ───────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _infoRow("Plan", isMonthly ? "Monthly (₹99)" : "Yearly (₹699)"),
                const Divider(height: 20),
                _infoRow("Status", "Active ✅"),
                const Divider(height: 20),
                _infoRow("Expires", passController.validUntil.value),
                const Divider(height: 20),
                _infoRow(
                  "Free deliveries left",
                  "$remaining / $cap this month",
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _activeBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ── PURCHASE UI ─────────────────────────────────────────────
  Widget _buildPurchaseUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HERO ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "🚀 Delivery Pass",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Unlimited free deliveries + exclusive coupons",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── PLAN SELECTOR ────────────────────────────────────
          const Text(
            "Choose a plan",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: plans.map((plan) {
                final isSelected = selectedPlan == plan["type"];
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => selectedPlan = plan["type"] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                        right: plan["type"] == "MONTHLY" ? 8 : 0,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (plan["tag"] != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                plan["tag"] as String,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 23),
                          Text(
                            plan["label"] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isSelected ? Colors.green : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            plan["price"] as String,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.green : Colors.black87,
                            ),
                          ),
                          Text(
                            plan["duration"] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan["cap"] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (plan["saving"] != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                plan["saving"] as String,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(height: 23),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isSelected ? "Selected" : "Select",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // ── WHAT YOU GET ─────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(selectedPlan),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "What you get",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          selectedPlan == "MONTHLY" ? "Monthly" : "Yearly",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...currentBenefits.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              b["icon"] as IconData,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              b["text"] as String,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── BUY BUTTON ───────────────────────────────────────
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: passPaymentController.isLoading.value
                    ? null
                    : () => passPaymentController.purchasePass(
                        planType: selectedPlan,
                        amount: selectedPlan == "MONTHLY" ? 99.0 : 699.0,
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: passPaymentController.isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Get ${selectedPlan == 'MONTHLY' ? '₹99 Monthly' : '₹699 Yearly'} Pass",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Center(
            child: Text(
              "No hidden charges • Instant activation",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
