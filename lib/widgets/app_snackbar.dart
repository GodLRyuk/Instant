import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// App-wide defaults for GetX snackbars so messages stay readable on any page.
class AppSnackbar {
  static SnackbarController show(
    String title,
    String message, {
    Color? colorText,
    Duration? duration,
    SnackPosition? snackPosition,
    EdgeInsets? margin,
    double? borderRadius,
    Color? backgroundColor,
  }) {
    return Get.snackbar(
      title,
      message,
      colorText: colorText ?? Colors.white,
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: snackPosition ?? SnackPosition.TOP,
      margin: margin ?? const EdgeInsets.all(12),
      borderRadius: borderRadius ?? 10,
      backgroundColor: backgroundColor ?? const Color(0xFF303030),
      barBlur: 0,
    );
  }
}
