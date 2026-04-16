import 'package:flutter/material.dart';

class GradeAssignedScreen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String locale;

  const GradeAssignedScreen({
    super.key,
    required this.onNext,
    this.onBack,
    required this.locale,
  });

  @override
  State<GradeAssignedScreen> createState() => _GradeAssignedScreenState();
}

class _GradeAssignedScreenState extends State<GradeAssignedScreen> {

  @override
  Widget build(BuildContext context) {
    bool isSomali = widget.locale == 'so';

    String titleSom = isSomali ? "HAMBALYO!" : "CONGRATULATIONS!";
    String titleEng = isSomali ? "Congratulations!" : "Hambalyo!";

    String levelSom = isSomali ? "Heerkaaga waa" : "Your level is";
    String levelEng = isSomali ? "Your level is:" : "Heerkaaga waa:";

    String gradeLabel = isSomali ? "FASALKA" : "GRADE";
    String gradeMain = isSomali ? "1aad" : "Grade 1";
    String gradeSecondary = isSomali ? "Grade 1" : "Fasalka 1aad";

    String btnNextSom = isSomali ? "Ku Bilow Waxbarashada" : "Start Learning";
    String btnNextEng = isSomali ? "Start Learning" : "Ku Bilow Waxbarashada";

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

                  SizedBox(
                    width: 140, // Wider for the final bar
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        value: 1.0, // Fully complete (or near complete)
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
                        color: const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Color(0xFF1D5AFF),
                      ),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    Text(
                      titleSom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1D5AFF),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      titleEng,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1333),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Robot Image Card
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 320,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            image: const DecorationImage(
                              image: NetworkImage(
                                "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?q=80&w=600&auto=format&fit=crop",
                              ), // Robot placeholder
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 20, right: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    Text(
                      "$levelSom / $levelEng",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Grade Blue Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D5AFF),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1D5AFF,
                            ).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 25, bottom: 15),
                            child: Column(
                              children: [
                                Text(
                                  gradeLabel,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  gradeMain,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 60,
                                  ),
                                  child: Divider(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    thickness: 1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  gradeSecondary,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Inner Action Button
                          GestureDetector(
                            onTap: widget.onNext,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF0F41D3,
                                ), // Darker shade than primary
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        btnNextSom,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        btnNextEng,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 15),
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

                    const SizedBox(height: 30),
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
