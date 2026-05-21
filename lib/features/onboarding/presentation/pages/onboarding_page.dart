import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../data/onboarding_prefs.dart';
import '../../../../shared/routes/app_routes.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingItem> _pages = [
    _OnboardingItem(
      image: 'assets/images/farmer_field.jpg',
      title: "Know what's attacking your crops",
      subtitle:
          'MbewuSmart uses AI to diagnose pests, diseases, and nutrient problems from a single photo.',
    ),
    _OnboardingItem(
      image: 'assets/images/farmer_phone.jpg',
      title: 'Learn from farmers across Malawi',
      subtitle:
          "See what pests and diseases other farmers in your region are reporting and how they're treating them.",
    ),
    _OnboardingItem(
      image: 'assets/images/farmer_tractor.jpg',
      title: 'Take action with confidence',
      subtitle:
          'Get treatment recommendations, alert your agricultural manager, and protect your harvest.',
    ),
  ];

  Future<void> _goToLogin() async {
    await OnboardingPrefs.markSeen();
    if (!mounted) return;
    try {
      context.go(AppRoutes.login);
    } catch (_) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  void _onNextPressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _goToLogin();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // FULL-SCREEN PAGEVIEW with images
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final item = _pages[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Full-screen image
                  Image.asset(
                    item.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.green.shade50,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 64,
                            color: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
                  // Dark gradient overlay on bottom half for text readability
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Color(0x99000000),
                          Color(0xCC000000),
                        ],
                        stops: [0.0, 0.4, 0.75, 1.0],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                  // Title and subtitle at the bottom of the image area
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 200,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            )
                            .animate(key: ValueKey('t-$index'))
                            .fadeIn(duration: 500.ms, delay: 150.ms)
                            .slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        Text(
                              item.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            )
                            .animate(key: ValueKey('s-$index'))
                            .fadeIn(duration: 500.ms, delay: 250.ms)
                            .slideY(begin: 0.1),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // SKIP BUTTON top-right (over the image)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: _goToLogin,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM AREA: page dots + Next button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: const ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: Colors.white,
                        dotColor: Colors.white54,
                        expansionFactor: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  final String image;
  final String title;
  final String subtitle;

  const _OnboardingItem({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
