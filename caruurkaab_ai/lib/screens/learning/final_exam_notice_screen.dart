import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/final_exam_service.dart';
import 'final_exam_question_screen.dart';
import 'student_dashboard.dart';

class FinalExamNoticeScreen extends StatefulWidget {
  final String? subjectName;
  final int? classLevel;
  final FinalExamRecord? initialExam;
  final bool returnToClassSubjectsOnFinish;

  const FinalExamNoticeScreen({
    super.key,
    this.subjectName,
    this.classLevel,
    this.initialExam,
    this.returnToClassSubjectsOnFinish = false,
  });

  @override
  State<FinalExamNoticeScreen> createState() => _FinalExamNoticeScreenState();
}

class _FinalExamNoticeScreenState extends State<FinalExamNoticeScreen> {
  static const List<String> _subjects = <String>[
    'Af Soomaali',
    'English',
    'Saynis',
    'Xisaab',
  ];

  bool _isLoading = true;
  String? _error;
  FinalExamRecord? _exam;
  SubjectScoreData? _scoreData;

  @override
  void initState() {
    super.initState();
    _loadExam();
  }

  Future<void> _loadExam() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final selected = await (() async {
        if (widget.initialExam != null) {
          return widget.initialExam;
        }

        FinalExamRecord? selected;

        final preferredSubject = widget.subjectName?.trim();
        final preferredClass = widget.classLevel;

        if (preferredSubject != null &&
            preferredSubject.isNotEmpty &&
            preferredClass != null) {
          final eligible = await FinalExamService.isEligibleForClassFinal(
            subject: preferredSubject,
            classLevel: preferredClass,
          );
          if (eligible) {
            selected = await FinalExamService.fetchClassFinalExam(
              subject: preferredSubject,
              classLevel: preferredClass,
            );
          }
        }

        if (selected == null) {
          final grandEligible =
              await FinalExamService.isEligibleForGrandFinal();
          if (grandEligible) {
            selected = await FinalExamService.fetchGrandFinalExam();
          }
        }

        if (selected == null) {
          final levels = <int>{?preferredClass, 1, 2, 3, 4}.toList();

          for (final level in levels) {
            for (final subject in _subjects) {
              final exam = await FinalExamService.fetchClassFinalExam(
                subject: subject,
                classLevel: level,
              );
              if (exam == null || !exam.isActive) continue;

              final eligible = await FinalExamService.isEligibleForClassFinal(
                subject: subject,
                classLevel: level,
              );
              if (eligible) {
                selected = exam;
                break;
              }
            }
            if (selected != null) break;
          }
        }

        return selected;
      })().timeout(const Duration(seconds: 15));

      SubjectScoreData? scoreData;
      if (selected != null && !selected.isGrandFinal) {
        scoreData = await FinalExamService.fetchCombinedSubjectScore(
          selected.subjectName,
          selected.classLevel,
          selected.id,
        );
      }

      if (widget.initialExam != null) {
        if (!mounted) return;
        setState(() {
          _exam = selected;
          _scoreData = scoreData;
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _exam = selected;
        _scoreData = scoreData;
        _isLoading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = null;
        _isLoading = false;
      });
    }
  }

  String _classLabel(FinalExamRecord exam) {
    return 'Fasalka ${exam.classLevel}';
  }

  void _startExam(FinalExamRecord exam) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FinalExamQuestionScreen(
          exam: exam,
          returnToClassSubjectsOnFinish: widget.returnToClassSubjectsOnFinish,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Final Exam',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorView()
              : _exam == null
              ? _buildNotReadyView()
              : _buildReadyView(_exam!),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 36),
            const SizedBox(height: 10),
            const Text(
              'Cillad ayaa timid',
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _loadExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5AFF),
              ),
              child: const Text('Isku day mar kale'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotReadyView() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: Color(0xFF1D5AFF), size: 36),
            SizedBox(height: 12),
            Text(
              'Final Exam wali diyaar kuu ma ahan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Marka hore dhammee casharrada, ka dibna baas leyliyada cutubyada.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyView(FinalExamRecord exam) {
    final title = exam.title.trim().isEmpty ? 'Final Exam' : exam.title.trim();
    final notice = exam.noticeText.trim().isEmpty
        ? 'Imtixaanka final-ka waa diyaar. Si deggan u akhri su’aalaha oo jawaab.'
        : exam.noticeText.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D5AFF), Color(0xFF4A7DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam.isGrandFinal ? 'Grand Final Exam' : 'Final Exam diyaar ah',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exam.isGrandFinal
                    ? 'Dhamaadka 4ta fasal'
                    : '${_classLabel(exam)} • ${exam.subjectName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_scoreData?.hasTakenFinal == true)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _scoreData!.isPassed
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _scoreData!.isPassed
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _scoreData!.isPassed ? Icons.check_circle : Icons.cancel,
                      color: _scoreData!.isPassed
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _scoreData!.isPassed
                            ? 'Waan kuugu Hambalyeynaayaa!'
                            : 'Natiijo Hoosaysa',
                        style: TextStyle(
                          color: _scoreData!.isPassed
                              ? const Color(0xFF065F46)
                              : const Color(0xFF991B1B),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Cutubyada:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          Text(
                            '${_scoreData!.chapterScoreOutOf40.round()} / 40',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Final Exam:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          Text(
                            '${_scoreData!.finalScoreOutOf60.round()} / 60',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Wadarta Guud:',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1D5AFF),
                            ),
                          ),
                          Text(
                            '${_scoreData!.totalScore.round()} / 100',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1D5AFF),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ogeysiis',
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notice,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '• Su’aalaha random ayaa kuu furmaya\n'
                  '• Ugu yaraan ${exam.passingScore}% waa inaad keentaa\n'
                  '• Jawaabta sax/qalad waxaa la tusayaa markaad dhammaayso',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        if (_scoreData?.isPassed == true)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassSubjectsScreen(
                      className: 'Class ${exam.classLevel}',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Horay u soco',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => _startExam(exam),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D5AFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _scoreData?.hasTakenFinal == true
                    ? 'Ku Celi Imtixaanka'
                    : 'Gal Final Exam',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
