import 'package:flutter/material.dart';

class SplashScreenView extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const SplashScreenView({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: Column(
          children: [
            // Top spacing instead of skip button
            const SizedBox(height: 40),

            const Spacer(),

            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D5AFF).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D5AFF),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D5AFF).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(
                    text: "Caruurkaab ",
                    style: TextStyle(color: Color(0xFF0D1333)),
                  ),
                  TextSpan(
                    text: "AI",
                    style: TextStyle(color: Color(0xFF1D5AFF)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Smart Learning for Kids",
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(flex: 2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(seconds: 3),
                onEnd: widget.onNext,
                builder: (context, value, _) {
                  final percent = (value * 100).round();
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "INITIALIZING",
                            style: TextStyle(
                              color: Color(0xFF1D5AFF),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "$percent%",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE5EDFF),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1D5AFF),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
