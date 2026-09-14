import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.94,
    ).animate(_fadeAnimation);
    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75,
    ).animate(_fadeAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF53D288),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF53D288),
                    Color.fromARGB(255, 136, 198, 65),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final opacity = (1.0 - _fadeAnimation.value).clamp(0.0, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Image.asset(
                              'assets/images/logo_transperent.png',
                              width: 170,
                              height: 170,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Instant Delivery',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Loading your experience...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return IgnorePointer(
                  child: Container(
                    color: Colors.white.withOpacity(_overlayAnimation.value),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
