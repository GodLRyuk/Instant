import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment {
  dev,
  prod;

  static AppEnvironment fromString(String value) {
    switch (value.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  String get value => this == AppEnvironment.prod ? 'prod' : 'dev';
}

class AppConfig {
  static AppEnvironment get environment {
    const buildEnv = String.fromEnvironment('APP_ENV', defaultValue: '');
    if (buildEnv.isNotEmpty) {
      return AppEnvironment.fromString(buildEnv);
    }

    final dotenvEnv = dotenv.env['APP_ENV']?.trim();
    if (dotenvEnv != null && dotenvEnv.isNotEmpty) {
      return AppEnvironment.fromString(dotenvEnv);
    }

    return kReleaseMode ? AppEnvironment.prod : AppEnvironment.dev;
  }

  static bool get isProduction => environment == AppEnvironment.prod;

  static String get baseUrl {
    final prodUrl = dotenv.env['PROD_BASE_URL']?.trim() ?? '';
    final devUrl = dotenv.env['DEV_BASE_URL']?.trim() ?? '';

    if (isProduction) {
      if (prodUrl.isNotEmpty) return prodUrl;
      if (devUrl.isNotEmpty) return devUrl;
      throw StateError(
        'PROD_BASE_URL is missing from .env for production builds.',
      );
    }

    if (devUrl.isNotEmpty) return devUrl;
    if (prodUrl.isNotEmpty) return prodUrl;
    throw StateError(
      'DEV_BASE_URL is missing from .env for development builds.',
    );
  }

  static String get wsUrl {
    final prodWsUrl = dotenv.env['PROD_WS_URL']?.trim() ?? '';
    final devWsUrl = dotenv.env['DEV_WS_URL']?.trim() ?? '';

    if (isProduction) {
      if (prodWsUrl.isNotEmpty) return prodWsUrl;
      if (devWsUrl.isNotEmpty) return devWsUrl;
      throw StateError(
        'PROD_WS_URL is missing from .env for production builds.',
      );
    }

    if (devWsUrl.isNotEmpty) return devWsUrl;
    if (prodWsUrl.isNotEmpty) return prodWsUrl;
    throw StateError('DEV_WS_URL is missing from .env for development builds.');
  }

  static void validateRuntimeConfiguration() {
    final baseUri = Uri.parse(baseUrl);
    if (isProduction && baseUri.scheme != 'https') {
      throw StateError('Base URL must use HTTPS in production builds.');
    }

    final wsUri = Uri.parse(wsUrl);
    if (isProduction && wsUri.scheme != 'wss') {
      throw StateError('WebSocket URL must use wss:// in production builds.');
    }
  }

  // --- API Keys (Hybrid Approach) ---
  static String get razorpayKey {
    // 1. Check if it was passed via command line --dart-define (Highest priority)
    const cmdLineKey = String.fromEnvironment('RAZORPAY_KEY');
    if (cmdLineKey.isNotEmpty) return cmdLineKey;

    // 2. Fallback to .env file (Development priority)
    final envKey = dotenv.env['RAZORPAY_KEY'] ?? '';
    if (envKey.isNotEmpty) return envKey;

    if (isProduction) {
      throw StateError('RAZORPAY_KEY is required in production builds.');
    }

    return 'rzp_test_StsVgck8iNAA8a';
  }

  // You can add other constants too
  static const int defaultConnectTimeout = 5; // seconds
  static const int defaultReceiveTimeout = 3; // seconds

  // Security Toggles
  static bool get allowRootedDevices => !isProduction;
  static bool get enforceScreenPrivacy => isProduction;
}
