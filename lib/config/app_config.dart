class AppConfig {
  // Base URL of your API
  static const String baseUrl = 'http://192.168.1.37:8000/api';
  static const String wsUrl = 'ws://192.168.1.37:8000'; // ✅ add this

  // static const String baseUrl =
  //     'https://web-production-a78c03.up.railway.app/api';

  // You can add other constants too
  static const int defaultConnectTimeout = 5; // seconds
  static const int defaultReceiveTimeout = 3; // seconds
}
