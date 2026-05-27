import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      bool isAvailable = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (!isAvailable || !isSupported) return false;

      return await auth.authenticate(
        localizedReason: 'Use fingerprint to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print("Biometric error: $e");
      return false;
    }
  }
}