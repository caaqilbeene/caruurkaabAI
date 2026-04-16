import 'package:flutter/material.dart';

import 'quiz_question_screen.dart';

class QuizIntroScreen extends StatelessWidget {
  final String lessonTitle;
  final String subjectName;
  final int classLevel;
  final String? chapterId;
  final String lessonId;
  final String? nextLessonId;
  final String? nextLessonTitle;
  final String? nextLessonChapterId;

  const QuizIntroScreen({
    super.key,
    required this.lessonTitle,
    required this.subjectName,
    required this.classLevel,
    this.chapterId,
    required this.lessonId,
    this.nextLessonId,
    this.nextLessonTitle,
    this.nextLessonChapterId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF111827)),
          onPressed: () {
            // Usually returns to the lesson list
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Decorative Graphic
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D5AFF).withValues(alpha: 0.1),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_rounded,
                    size: 70,
                    color: Color(0xFF1D5AFF),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Text Content
              Text(
                "Quiz‑ka Casharka",
                style: const TextStyle(
                  color: Color(0xFF1D5AFF),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Tijaabi Fahamkaaga:\n$lessonTitle",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Waxaad haysataa fursad aad ku xaqiijiso inta aad ka fahamtay casharkan. Si fiican uga fiirso jawaabahaaga ka hor intaanad dooran.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              // Info Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildInfoChip(Icons.format_list_bulleted, "5 Su'aalood"),
                  const SizedBox(width: 15),
                  _buildInfoChip(Icons.timer, "Waqti la'aan"),
                ],
              ),

              const Spacer(),

              // Action Button
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizQuestionScreen(
                        lessonTitle: lessonTitle,
                        subjectName: subjectName,
                        classLevel: classLevel,
                        chapterId: chapterId,
                        lessonId: lessonId,
                        nextLessonId: nextLessonId,
                        nextLessonTitle: nextLessonTitle,
                        nextLessonChapterId: nextLessonChapterId,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D5AFF),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D5AFF).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "BILOW QUIZ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4B5563)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
