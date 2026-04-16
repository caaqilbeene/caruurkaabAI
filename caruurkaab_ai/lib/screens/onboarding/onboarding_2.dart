import 'package:flutter/material.dart';

class OnboardingScreen2 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String locale;

  const OnboardingScreen2({
    super.key,
    required this.onNext,
    this.onBack,
    required this.locale,
  });

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  @override
  Widget build(BuildContext context) {
    bool isSomali = widget.locale == 'so';

    String title = isSomali ? "Ku Baro AI" : "Learn with AI";
    String description = isSomali
        ? "Caruurtaadu waxay si casri ah ugu baran karaan casharrada iyagoo adeegsanaya caawinaada AI."
        : "Your kids can modernly learn lessons using AI assistance.";
    String btnText = isSomali ? "Bilow" : "Get Started";

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black87,
                      ),
                      onPressed: widget.onBack,
                    )
                  else
                    const SizedBox(width: 48),
                  const Text(
                    "Caruurkab AI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1333),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const Spacer(),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              height: 300,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCE6FF), Color(0xFFEFF4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5AFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            Text(
              title,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D1333),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(false),
                _buildDot(false),
                _buildDot(true),
                _buildDot(false),
              ],
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D5AFF),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF1D5AFF).withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      btnText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: active ? 30 : 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1D5667) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
