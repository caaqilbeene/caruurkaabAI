import 'package:flutter/material.dart';

class OnboardingScreen1 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkip;
  final String locale;

  const OnboardingScreen1({
    super.key,
    required this.onNext,
    this.onBack,
    required this.onSkip,
    required this.locale,
  });

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1> {
  @override
  Widget build(BuildContext context) {
    bool isSomali = widget.locale == 'so';

    String title = isSomali ? "Baro Afkaaga" : "Learn Your Language";
    String description = isSomali
        ? "Si fudud ugu baro luuqadda\nSoomaaliga app-ka Caruurkab."
        : "Easily learn the Somali language\nwith the Caruurkab app.";
    String btnText = isSomali ? "Xigta" : "Next";
    String skipText = isSomali ? "Ka bood" : "Skip";

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
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      skipText,
                      style: const TextStyle(
                        color: Color(0xFF1D5AFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Image Placeholder area with shape
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFF1D5AFF),
                      size: 110,
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    right: 20,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          color: Color(0xFF1D5AFF),
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                ],
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
                _buildDot(true),
                _buildDot(false),
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
        color: active ? const Color(0xFF1D5AFF) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
