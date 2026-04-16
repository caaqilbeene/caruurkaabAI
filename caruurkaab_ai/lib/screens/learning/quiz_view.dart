import 'package:flutter/material.dart';

// import '../dashboard/animal_quiz_result_screen.dart';

class QuizViewScreen extends StatefulWidget {
  const QuizViewScreen({super.key});

  @override
  State<QuizViewScreen> createState() => _QuizViewScreenState();
}

class _QuizViewScreenState extends State<QuizViewScreen> {
int _selectedAnswerIndex = -1;

  @override
  Widget build(BuildContext context) {
    String titleEng = "Identify the Camel";
    String titleSom = "(Dooro sawirka geela)";

    String btnText = "GUDBI JAWAABTA";
    String btnSubText = "SUBMIT ANSWER";

    final options = [
      {"emoji": "🦁", "eng": "Lion", "som": "Libaax"},
      {"emoji": "🐪", "eng": "Camel", "som": "Geel"},
      {"emoji": "🐘", "eng": "Elephant", "som": "Maroodi"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          "CARUURKAB AI",
                          style: TextStyle(
                            color: Color(0xFF1D5AFF),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Su'aasha 3 ee 10",
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the flex row
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Horumarka / Progress",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const Text(
                        "30%",
                        style: TextStyle(
                          color: Color(0xFF1D5AFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      value: 0.3,
                      minHeight: 8,
                      backgroundColor: Color(0xFFEEF2FF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF1D5AFF),
                      ),
                    ),
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
                    // Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Color(0xFF1D5AFF),
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Titles
                    Text(
                      titleEng,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1333),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      titleSom,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Answer Options
                    for (int i = 0; i < options.length; i++)
                      _buildAnswerOption(
                        index: i,
                        emoji: options[i]["emoji"]!,
                        title1: options[i]["som"]!,
                        title2: options[i]["eng"]!,
                        isSelected: _selectedAnswerIndex == i,
                        onTap: () {
                          setState(() {
                            _selectedAnswerIndex = i;
                          });
                        },
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _selectedAnswerIndex != -1
                        ? () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) =>
                            //         const AnimalQuizResultScreen(),
                            //   ),
                            // );
                          }
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: _selectedAnswerIndex != -1
                            ? const Color(0xFF1D5AFF)
                            : const Color(
                                0xFF9CA3AF,
                              ), // Blue if active, grey if disabled
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: _selectedAnswerIndex != -1
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1D5AFF,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            btnText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    btnSubText,
                    style: const TextStyle(
                      color: Color(0xFF9ca3af),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOption({
    required int index,
    required String emoji,
    required String title1,
    required String title2,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFECFDF5)
              : Colors.white, // Light green if selected
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981) // Green border
                : const Color(0xFFF3F4F6), // Light gray
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title1,
                    style: TextStyle(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title2,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF10B981) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 16, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
