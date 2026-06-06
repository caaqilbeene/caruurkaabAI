import 'package:flutter/material.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/auth/login_signup.dart';

class MainFlow extends StatefulWidget {
  const MainFlow({super.key});

  @override
  State<MainFlow> createState() => _MainFlowState();
}

class _MainFlowState extends State<MainFlow> {
  final PageController _pageController = PageController();

  void _nextPage() {
    if (_pageController.hasClients && _pageController.page! < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disables swiping so buttons must be used
        children: [
          // 1. Caruurkaab AI (Splash)
          SplashScreenView(onNext: _nextPage, onSkip: _nextPage),

          // 2. Sign In
          const LoginPage(),
        ],
      ),
    );
  }
}
