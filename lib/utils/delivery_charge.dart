class DeliveryCharge {
  static double calculate(double totalAmount) {
    if (totalAmount > 500) {
      return 0;
    } else if (totalAmount > 200) {
      return 25;
    } else {
      return 35;
    }
  }
}
