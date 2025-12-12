import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to Tmelnik',
      description: 'Discover amazing volunteer projects and opportunities around the world.',
      icon: Icons.explore,
      color: AppColors.primaryBlue,
      lottieUrl: 'https://lottie.host/embed/4f5b8c9d-1a2b-3c4d-5e6f-7a8b9c0d1e2f.json', // Explore animation
    ),
    OnboardingPage(
      title: 'Apply to Projects',
      description: 'Browse projects from NGOs and apply directly through the app. Track your applications easily.',
      icon: Icons.work,
      color: Colors.green,
      lottieUrl: 'https://lottie.host/embed/5g6c9d0e-2b3c-4d5e-6f7a-8b9c0d1e2f3a.json', // Work/Apply animation
    ),
    OnboardingPage(
      title: 'Stay Updated',
      description: 'Get notifications about new projects and important updates. Never miss an opportunity!',
      icon: Icons.notifications,
      color: Colors.orange,
      lottieUrl: 'https://lottie.host/embed/6h7d0e1f-3c4d-5e6f-7a8b-9c0d1e2f3b4c.json', // Notification animation
    ),
    OnboardingPage(
      title: 'Track Your Journey',
      description: 'Keep a personal diary and reflect on your experiences. Document your growth.',
      icon: Icons.book,
      color: Colors.purple,
      lottieUrl: 'https://lottie.host/embed/7i8e1f2g-4d5e-6f7a-8b9c-0d1e2f3b4c5d.json', // Book/Journey animation
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    if (mounted) {
      // Just pop or let AuthWrapper handle the navigation
      // The AuthWrapper will automatically show the auth screen or main app
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            
            // Page view with animations
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return PageTransitionSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation, secondaryAnimation) {
                      return FadeThroughTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        child: child,
                      );
                    },
                    child: _buildPage(_pages[index], key: ValueKey(index)),
                  );
                },
              ),
            ),
            
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildIndicator(index == _currentPage),
              ),
            ),
            const SizedBox(height: 32),
            
            // Animated Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 800.ms)
                    .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 800.ms, curve: Curves.easeOut),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated illustration container with Lottie or animated icon
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.color.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Try to load Lottie animation, fallback to animated icon
                if (page.lottieUrl != null)
                  Lottie.network(
                    page.lottieUrl!,
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to animated icon if Lottie fails
                      return Icon(
                        page.icon,
                        size: 120,
                        color: page.color,
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(duration: 2000.ms, color: page.color.withOpacity(0.5))
                          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1500.ms, curve: Curves.easeInOut);
                    },
                  )
                else
                  Icon(
                    page.icon,
                    size: 120,
                    color: page.color,
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 2000.ms, color: page.color.withOpacity(0.5))
                      .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1500.ms, curve: Curves.easeInOut),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 700.ms, delay: 200.ms, curve: Curves.easeOutBack)
              .then()
              .shimmer(duration: 1000.ms, color: page.color.withOpacity(0.3)),
          
          const SizedBox(height: 48),
          
          // Animated title
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 400.ms, curve: Curves.easeOut),
          
          const SizedBox(height: 16),
          
          // Animated description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 600.ms)
              .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 600.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryBlue : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? lottieUrl;
  final String? imageUrl;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.lottieUrl,
    this.imageUrl,
  });
}

