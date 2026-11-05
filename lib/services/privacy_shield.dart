import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:instant_delivery/config/app_config.dart';

class PrivacyShield extends StatefulWidget {
  final Widget child;
  const PrivacyShield({super.key, required this.child});

  @override
  State<PrivacyShield> createState() => _PrivacyShieldState();
}

class _PrivacyShieldState extends State<PrivacyShield>
    with WidgetsBindingObserver {
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!AppConfig.enforceScreenPrivacy) return;

    setState(() {
      // Inactive or Paused means the user is switching apps or has minimized it
      _isBackgrounded =
          (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBackgrounded) return widget.child;

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        widget.child,
        // Overlay a blur and a logo when in background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Image.asset(
                'assets/images/logo_transperent.png',
                width: 150,
                height: 150,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
