import 'package:flutter/material.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/onboarding/language_selection.dart';
import 'screens/onboarding/onboarding_1.dart';
import 'screens/onboarding/onboarding_2.dart';
import 'screens/auth/login_signup.dart';

class MainFlow extends StatefulWidget {
  const MainFlow({super.key});

  @override
  State<MainFlow> createState() => _MainFlowState();
}

class _MainFlowState extends State<MainFlow> {
  final PageController _pageController = PageController();

  // 'so' for Somali, 'en' for English
  String _locale = 'so';

  void _nextPage() {
    if (_pageController.hasClients && _pageController.page! < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_pageController.hasClients && _pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToLogin() {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        4, // Login screen index
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _setLanguage(String langCode) {
    setState(() {
      _locale = langCode;
    });
    _nextPage();
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
          SplashScreenView(onNext: _nextPage, onSkip: _skipToLogin),

          // 2. Dooro Luqada
          LanguageSelection(
            onSelectSomali: () => _setLanguage('so'),
            onSelectEnglish: () => _setLanguage('en'),
            onBack: _previousPage,
          ),

          // 3. Baro Afkaaga
          OnboardingScreen1(
            onNext: _nextPage,
            onBack: _previousPage,
            onSkip: _skipToLogin,
            locale: _locale,
          ),

          // 4. Ku Baro AI
          OnboardingScreen2(
            onNext: _nextPage,
            onBack: _previousPage,
            locale: _locale,
          ),

          // 5. Sign In
          const LoginPage(),
        ],
      ),
    );
  }
}
