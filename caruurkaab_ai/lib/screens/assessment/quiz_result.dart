import 'package:flutter/material.dart';

class QuizResultScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String locale;

  const QuizResultScreen({
    super.key,
    required this.onNext,
    this.onBack,
    required this.locale,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {

  @override
  Widget build(BuildContext context) {
    bool isSomali = widget.locale == 'so';

    String titleSom = isSomali ? "Hambalyo!" : "Congratulations!";
    String titleEng = isSomali ? "Congratulations!" : "Hambalyo!";

    String cardHeader = isSomali ? "NATIIJADA / RESULT" : "RESULT / NATIIJADA";
    String resultMain1 = isSomali ? "Waa lagu guuleystay!" : "You passed!";
    String resultMain2 = isSomali ? "/ You passed!" : "/ Waa lagu guuleystay!";

    String quote1 = isSomali
        ? "\"Shaqo fiican ayaad qabatay, sii wad\ndadaalkaaga!\""
        : "\"You did a great job, keep up the\neffort!\"";
    String quote2 = isSomali
        ? "\"You did a great job, keep up the\neffort!\""
        : "\"Shaqo fiican ayaad qabatay, sii wad\ndadaalkaaga!\"";

    String box1Title = isSomali ? "SAX / CORRECT" : "CORRECT / SAX";
    String box2Title = isSomali ? "HEERKA / LEVEL" : "LEVEL / HEERKA";

    String btnNext = isSomali ? "Sii wad / Next" : "Next / Sii wad";

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
                  const SizedBox(width: 48), // Balance for centering
                  SizedBox(
                    width: 60,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 0.6,
                        minHeight: 6,
                        backgroundColor: Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1D5AFF),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    onPressed: widget.onBack,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 25,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Trophy Image
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.1),
                            border: Border.all(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.emoji_events,
                              size: 70,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10, right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Titles
                    Text(
                      titleSom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1333),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      titleEng,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D5AFF),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Main Success Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cardHeader,
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      resultMain1,
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        height: 1.3,
                                      ),
                                    ),
                                    Text(
                                      resultMain2,
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),
                          const Divider(color: Color(0xFFD1FAE5)),
                          const SizedBox(height: 20),

                          Center(
                            child: Column(
                              children: [
                                Text(
                                  quote1,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  quote2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF1D5AFF),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  box1Title,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "10 / 10",
                                  style: TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.school,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  box2Title,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "C-1",
                                  style: TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar Fixed
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D5AFF),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF1D5AFF).withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      btnNext,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
