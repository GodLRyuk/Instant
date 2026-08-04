import 'package:flutter/foundation.dart';

class LogService {
  /// Prints a message only in debug mode. 
  /// This prevents sensitive data (like tokens) from being visible in 
  /// production logs (logcat/syslog).
  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print("[DEBUG] $message");
      if (error != null) print("Error: $error");
      if (stackTrace != null) print("Stack: $stackTrace");
    }
  }

  /// Use for critical errors that should be logged even in release 
  /// (but ensure no PII or tokens are passed here).
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    print("[ERROR] $message");
    if (error != null) print("Error: $error");
    // Consider integrating a service like Sentry or Crashlytics here for release
  }
}
