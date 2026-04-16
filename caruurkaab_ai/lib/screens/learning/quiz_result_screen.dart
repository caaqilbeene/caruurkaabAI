import 'package:flutter/material.dart';

import 'quiz_question_screen.dart';
import 'lesson_list_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final String lessonTitle;
  final String subjectName;
  final int classLevel;
  final String? chapterId;
  final String lessonId;
  final String? nextLessonId;
  final String? nextLessonTitle;
  final String? nextLessonChapterId;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.total,
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
    final double percentage = (score / total) * 100;
    final bool isPass = percentage >= 60; // 60% to pass

    final Color statusColor = isPass
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    final String statusText = isPass
        ? "Waa Gudubtay (Pass) ✅"
        : "Hadhacday (Fail) ❌";
    final IconData statusIcon = isPass ? Icons.emoji_events : Icons.mood_bad;
    final className = 'Fasalka $classLevel';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Status Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: isPass
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(statusIcon, size: 70, color: statusColor),
                ),
              ),

              const SizedBox(height: 40),

              // Status Text
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Natiijada Quiz‑ka $lessonTitle",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 40),

              // Score Card
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "SCORE",
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "$score / $total",
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: const Color(0xFFE5E7EB),
                    ),
                    Column(
                      children: [
                        const Text(
                          "PERCENTAGE",
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${percentage.toInt()}%",
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              if (!isPass)
                InkWell(
                  onTap: () {
                    // Retry
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
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "KUCELI (RETRY)",
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              InkWell(
                onTap: () {
                  final nextId = nextLessonId?.trim() ?? '';
                  if (nextId.isNotEmpty) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonListScreen(
                          subjectName: subjectName,
                          className: className,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).popUntil(
                      (route) => route.isFirst || route.settings.name == '/home',
                    );
                  }
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
                    "SII WAD (CONTINUE)",
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
}
