import 'package:flutter/material.dart';

class LanguageSelection extends StatefulWidget {
  final VoidCallback onSelectSomali;
  final VoidCallback onSelectEnglish;
  final VoidCallback? onBack;

  const LanguageSelection({
    super.key,
    required this.onSelectSomali,
    required this.onSelectEnglish,
    this.onBack,
  });

  @override
  State<LanguageSelection> createState() => _LanguageSelectionState();
}

class _LanguageSelectionState extends State<LanguageSelection> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                    "Step 1 of 4",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance
                ],
              ),
            ),

            const Spacer(),

            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE5EDFF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: Icon(Icons.face, size: 50, color: Color(0xFF1D5AFF)),
              ),
            ),

            const SizedBox(height: 30),

            // Titles
            const Text(
              "Dooro Luuqadda",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D1333),
              ),
            ),
            const Text(
              "Choose Language",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1D5AFF),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              "Ku soo dhawaad Caruurkab AI\nWelcome to Caruurkab AI",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 40),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton(
                onPressed: widget.onSelectSomali,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.translate, color: Colors.white),
                    ),
                    const Text(
                      "Af-Soomaali",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton(
                onPressed: widget.onSelectEnglish,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.language, color: Colors.white),
                    ),
                    const Text(
                      "English",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            // Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(true),
                _buildDot(false),
                _buildDot(false),
                _buildDot(false),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              width: 140,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),
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
