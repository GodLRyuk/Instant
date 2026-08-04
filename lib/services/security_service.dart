import 'dart:io';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:instant_delivery/config/app_config.dart';
import 'package:instant_delivery/services/log_service.dart';
import 'package:screen_protector/screen_protector.dart';

class SecurityService {
  /// Prevents screenshots and hides app content in the Task Switcher (Android only).
  /// This is critical for protecting sensitive data like payment screens.
  static Future<void> initializeScreenPrivacy() async {
    if (Platform.isAndroid && AppConfig.enforceScreenPrivacy) {
      try {
        await ScreenProtector.protectDataLeakageOn();
        LogService.d("Screen privacy enabled via screen_protector");
      } catch (e) {
        LogService.e("Failed to enable screen privacy", error: e);
      }
    }
  }

  /// Checks if the device is rooted (Android) or jailbroken (iOS).
  /// Rooted devices are more vulnerable to data theft.
  static Future<bool> isDeviceCompromised() async {
    try {
      bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      bool developerMode = await FlutterJailbreakDetection.developerMode;

      if (jailbroken) {
        LogService.e("Device is jailbroken/rooted!");
        return true;
      }

      if (developerMode && !AppConfig.allowRootedDevices) {
        LogService.d("Developer mode detected and restricted");
        return true;
      }

      return false;
    } catch (e) {
      LogService.e("Compromise check error", error: e);
      return false;
    }
  }
}
