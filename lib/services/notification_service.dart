import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'orders',
        channelName: 'Order Updates',
        channelDescription: 'Notifications for order status updates',
        defaultColor: Colors.blue,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: true,
      ),
    ]);

    await AwesomeNotificationsFcm().initialize(
      onFcmSilentDataHandle: onFcmSilentDataHandle,
      onFcmTokenHandle: onFcmTokenHandle,
      onNativeTokenHandle: onNativeTokenHandle,
      licenseKeys: null,
      debug: true,
    );

    await requestPermission();
  }

  static Future<void> requestPermission() async {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  // ✅ This is what setListeners points to
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction action) async {
    final String? type = action.payload?['type'];

    // Navigate based on notification type using GetX
    switch (type) {
      case 'order_placed':
        Get.toNamed('/order-detail', arguments: action.payload?['order_id']);
        break;
      case 'order_on_the_way':
        Get.toNamed('/order-tracking', arguments: action.payload?['order_id']);
        break;
      case 'order_delivered':
        Get.toNamed('/order-detail', arguments: action.payload?['order_id']);
        break;
      default:
        Get.toNamed('/home');
    }
  }

  @pragma('vm:entry-point')
  @pragma('vm:entry-point')
  static Future<void> onFcmTokenHandle(String token) async {
    // ✅ Save to SharedPreferences (backup)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);

    // ✅ Send to your Python backend
    try {
      await ApiService().saveDeviceToken(token);
    } catch (e) {
      LogService.e('Could not save token to backend', error: e);
    }
  }

  @pragma('vm:entry-point')
  static Future<void> onNativeTokenHandle(String token) async {
    LogService.d('Native Token: $token');
  }

  @pragma('vm:entry-point')
  static Future<void> onFcmSilentDataHandle(FcmSilentData silentData) async {
    LogService.d('Silent data: ${silentData.data}');
  }

  static Future<String?> getDeviceToken() async {
    return await AwesomeNotificationsFcm().requestFirebaseAppToken();
  }
}
