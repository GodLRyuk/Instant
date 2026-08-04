import 'package:flutter/foundation.dart';

class LogService {
  static String sanitize(String value) {
    try {
      return value
          .replaceAll(
            RegExp(
              r'(token|password|secret|authorization)=([^\s,;]+)',
              caseSensitive: false,
            ),
            r'$1=[REDACTED]',
          )
          .replaceAll(
            RegExp(r'\b(bearer)\s+[A-Za-z0-9._\-]+', caseSensitive: false),
            r'$1 [REDACTED]',
          );
    } catch (_) {
      return value;
    }
  }

  /// Prints a message only in debug mode.
  /// This prevents sensitive data (like tokens) from being visible in
  /// production logs (logcat/syslog).
  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print("[DEBUG] ${sanitize(message)}");
      if (error != null) print("Error: ${sanitize(error.toString())}");
      if (stackTrace != null)
        print("Stack: ${sanitize(stackTrace.toString())}");
    }
  }

  /// Use for critical errors that should be logged even in release
  /// (but ensure no PII or tokens are passed here).
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    print("[ERROR] ${sanitize(message)}");
    if (error != null) print("Error: ${sanitize(error.toString())}");
    if (stackTrace != null) print("Stack: ${sanitize(stackTrace.toString())}");
    // Consider integrating a service like Sentry or Crashlytics here for release
  }
}
