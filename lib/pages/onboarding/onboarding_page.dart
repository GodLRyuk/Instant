import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instant_delivery/pages/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      image: 'assets/images/slide1.png',
      title: 'Everything You Need',
      subtitle: 'Daily essentials delivered fresh and fast to your door.',
    ),
    _OnboardingSlide(
      image: 'assets/images/slide2.png',
      title: 'Shop Your Favorites',
      subtitle: 'Browse products, discover new arrivals, and find great deals.',
    ),
    _OnboardingSlide(
      image: 'assets/images/slide3.png',
      title: 'Instant Delivery',
      subtitle: 'Your everyday shopping, made simple in just one tap.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _getStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _nextPage() {
    if (_currentPage == _slides.length - 1) {
      _getStarted();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF5F8E8);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBody: true,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return ColoredBox(
                    color: const Color(0xFFF5F8E8),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        slide.image,
                        // width: double.infinity,
                        fit: BoxFit.fill,
                        height: double.infinity,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_currentPage < _slides.length - 1)
                      TextButton(
                        onPressed: _getStarted,
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.black87, fontSize: 15),
                        ),
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: index == _currentPage ? 24 : 8,
                          decoration: BoxDecoration(
                            color: index == _currentPage
                                ? const Color(0xFFFF5A1F)
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5A1F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _currentPage == _slides.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String image;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
